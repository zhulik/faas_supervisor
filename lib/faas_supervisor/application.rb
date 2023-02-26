# frozen_string_literal: true

class FaasSupervisor::Application
  extend FaasSupervisor::Injector

  include Singleton

  include FaasSupervisor
  include Memery
  include Logger

  inject :openfaas
  inject :kubernetes
  inject :bus

  memoize def container = Dry::Container.new

  def run
    init_container!
    set_traps!

    start_metrics_collector!
    start_metrics_server!
    start_function_listener!

    start_self_deployer! unless config.self_update_interval.zero?

    info { "Started" }
  rescue StandardError => e
    fatal { e }
    stop
    exit(1)
  end

  def stop
    bus.close
    parent.stop
    openfaas.close
    info { "Stopped" }
  end

  private

  memoize def config = Config.build
  memoize def parent = Async::Barrier.new

  def start_metrics_server! = Metrics::Server.new(port: config.metrics_server_port, parent:).run
  def start_metrics_collector! = Metrics::Collector.new(parent:).run
  def start_function_listener! = FunctionListener.new(parent:, update_interval: config.update_interval).run

  def start_self_deployer!
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

  def init_container! # rubocop:disable Metrics/AbcSize
    {
      openfaas: Openfaas::Client.new(url: config.openfaas_url,
                                     username: config.openfaas_username,
                                     password: config.openfaas_password),
      kubernetes: Kubernetes::Client.new(host: config.kubernetes_url,
                                         scheme: config.kubernetes_scheme),
      prometheus: ::Prometheus::ApiClient.client(url: config.prometheus_url),
      metrics_store: Metrics::Store.new,
      bus: Async::Bus::Bus.new(parent:)
    }.each { container.register(_1, _2) }
  end
end
