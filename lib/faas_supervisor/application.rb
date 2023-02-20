# frozen_string_literal: true

class FaasSupervisor::Application
  include FaasSupervisor::Helpers

  option :config, type: T.Instance(Config)

  inject :openfaas
  inject :metrics_store

  class << self
    def config = FaasSupervisor::Config.build
    def build = new(config:)
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
    metrics_collector.run
    metrics_server.run

    timer.start

    info { "Started, update interval: #{config.update_interval}" }
  end

  def stop
    timer.stop

    supervisors.stop
    metrics_collector.stop
    metrics_server.stop

    openfaas.close
  end

  private

  memoize def timer = Async::Timer.new(config.update_interval, start: false, run_on_start: true) { cycle }
  memoize def supervisors = Supervisors.new
  memoize def container = Container.new(config)
  memoize def metrics_server = Metrics::Server.new(port: config.metrics_server_port)
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
end
