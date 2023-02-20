# frozen_string_literal: true

class FaasSupervisor::Application
  include FaasSupervisor::Helpers

  DEFAULT_KUBERNETES_HOST = "127.0.0.1"
  DEFAULT_KUBERNETES_PORT = 8001

  option :openfaas_url, type: T::String
  option :openfaas_username, type: T::String
  option :openfaas_password, type: T::String

  option :prometheus_url, type: T::String

  option :kubernetes_url, type: T::String
  option :kubernetes_scheme, type: T::Coercible::String

  option :update_interval, type: T::Coercible::Integer, default: -> { 10 }

  option :metrics_server_port, type: T::Coercible::Integer, default: -> { 8080 }

  inject :openfaas
  inject :metrics_store

  class << self
    def config # rubocop:disable Metrics/MethodLength
      kubernetes_host = ENV.fetch("KUBERNETES_SERVICE_HOST", DEFAULT_KUBERNETES_HOST)
      kubernetes_port = ENV.fetch("KUBERNETES_SERVICE_PORT", DEFAULT_KUBERNETES_PORT)

      kubernetes_scheme = kubernetes_host == DEFAULT_KUBERNETES_HOST ? :http : :https
      {
        openfaas_url: ENV.fetch("OPENFAAS_URL"),
        openfaas_username: ENV.fetch("OPENFAAS_USERNAME"),
        openfaas_password: ENV.fetch("OPENFAAS_PASSWORD"),

        prometheus_url: ENV.fetch("PROMETHEUS_URL", "http://127.0.0.1:9090"),

        update_interval: ENV.fetch("SUPERVISOR_UPDATE_INTERVAL", "10"),

        metrics_server_port: ENV.fetch("SUPERVISOR_METRICS_SERVER_PORT", "8080"),
        kubernetes_url: "#{kubernetes_host}:#{kubernetes_port}",
        kubernetes_scheme:
      }
    end

    def build
      new(**config)
    end

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

    metrics_store.set("functions", functions.count)

    supervisors.update(functions)
  rescue StandardError => e
    warn(e)
  end

  def force_exit
    fatal { "Forced exit" }
    exit(1)
  end

  def init_container! # rubocop:disable Metrics/AbcSize
    container.register(:openfaas, Openfaas::Client.new(url: openfaas_url,
                                                       username: openfaas_username,
                                                       password: openfaas_password))
    container.register(:prometheus, Prometheus::ApiClient.client(url: prometheus_url))
    container.register(:metrics_store, Metrics::Store.new)
    container.register(:kubernetes, Kubernetes::Client.new(host: kubernetes_url, scheme: kubernetes_scheme))
  end
end
