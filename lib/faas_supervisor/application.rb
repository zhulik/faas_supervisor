# frozen_string_literal: true

class FaasSupervisor::Application
  include FaasSupervisor::Helpers

  option :config, type: T.Instance(Config)

  inject :openfaas
  inject :metrics_store
  inject :kubernetes
  inject :bus

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
    start_metrics_collector!
    start_metrics_server!
    start_self_deployer!

    Async::Timer.new(config.update_interval, run_on_start: true, parent:, call: self)

    info { "Started, update interval: #{config.update_interval}" }
  end

  def stop
    parent.stop

    bus.close
    openfaas.close
  end

  # TODO: add timeout
  def call
    functions = openfaas.functions
    debug { "Functions found: #{functions.count}" }

    metrics_store.set("functions", functions.count)

    supervisors.update(functions)
  rescue StandardError => e
    warn(e)
  end

  private

  memoize def container = Container.new(config)
  memoize def supervisors = Supervisors.new(parent:)
  memoize def parent = Async::Barrier.new

  def start_metrics_server! = Metrics::Server.new(port: config.metrics_server_port, parent:).run
  def start_metrics_collector! = Metrics::Collector.new(parent:).run

  def start_self_deployer!
    return if config.self_update_interval.zero?

    Deployer.new(deployment_name: config.deployment_name,
                 namespace: kubernetes.current_namespace,
                 interval: config.self_update_interval,
                 parent:).run
  end

  def set_traps!
    trap("INT") do
      force_exit! if @stopping
      @stopping = true
      warn { "Interrupted, stopping. Press ^C once more to force exit." }
      stop
    end

    trap("TERM") { stop }
  end

  def force_exit!
    fatal { "Forced exit" }
    exit(1)
  end
end
