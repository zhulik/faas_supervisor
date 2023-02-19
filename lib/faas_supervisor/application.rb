# frozen_string_literal: true

class FaasSupervisor::Application
  include FaasSupervisor::Helpers

  option :openfaas_url, type: T::String
  option :openfaas_username, type: T::String
  option :openfaas_password, type: T::String
  option :prometheus_url, type: T::String
  option :update_interval, type: T::Coercible::Integer, default: -> { 10 }
  option :metrics_server_port, type: T::Coercible::Integer, default: -> { 8080 }

  inject :openfaas
  inject :metrics_store

  class << self
    def instance = @@instance

    def [](key) = instance[key]
  end

  def initialize(*, **)
    super(*, **)
    @@instance = self # rubocop:disable Style/ClassVars
  end

  def [](key) = container[key]

  def run
    set_traps!
    init_container!
    metrics_collector.run
    metrics_server.run

    timer.start

    info { "Started, update interval: #{update_interval}" }
  end

  def stop
    timer.stop

    supervisors.stop
    metrics_collector.stop
    metrics_server.stop

    self[:openfaas].close
  end

  private

  memoize def timer = Async::Timer.new(update_interval, start: false, run_on_start: true) { cycle }
  memoize def supervisors = Supervisors.new
  memoize def container = Dry::Container.new
  memoize def metrics_server = Metrics::Server.new(port: metrics_server_port)
  memoize def metrics_collector = Metrics::Collector.new

  def set_traps!
    trap("INT") do
      force_exit if @stopping
      @stopping = true
      warn { "Interrupted, stopping. Press ^C once more to force exit." }
      stop
    end

    trap("TERM") { stop }
  end

  # TODO: add timeout
  def cycle
    functions = openfaas.functions
    debug { "Functions found: #{functions.count}" }

    metrics_store.set("functions_total", functions.count)

    supervisors.update(functions)
  rescue StandardError => e
    warn(e)
  end

  def force_exit
    fatal { "Forced exit" }
    exit(1)
  end

  def init_container!
    container.register(:openfaas, Openfaas::Client.new(url: openfaas_url,
                                                       username: openfaas_username,
                                                       password: openfaas_password))
    container.register(:prometheus, Prometheus::ApiClient.client(url: prometheus_url))
    container.register(:metrics_store, Metrics::Store.new)
  end
end
