# frozen_string_literal: true

class FaasSupervisor::Application
  extend FaasSupervisor::Injector

  include Singleton

  include FaasSupervisor
  include Memery
  include Logger

  inject :kubernetes

  memoize def container = Container.new(config)

  def run
    @task = Async::Task.current
    set_traps!

    start_notifier!
    start_metrics_server!
    start_ruby_runtime_monitor!
    start_metrics_collector!
    start_function_listener!
    start_self_deployer!

    info { "Started" }
  rescue StandardError => e
    fatal { e }
    stop
    exit(1)
  end

  def stop
    @task&.stop
    info { "Stopped" }
  end

  private

  memoize def config = Config.build

  def start_ruby_runtime_monitor! = Metrics::RubyRuntimeMonitor.new.run
  def start_function_listener! = FunctionListener.new(update_interval: config.update_interval).run
  def start_metrics_collector! = MetricsCollector.new.run
  def start_metrics_server! = Metrics::Server.new(prefix: :faas_supervisor, port: config.metrics_server_port).run

  def start_notifier!
    return unless config.notification_webhook_url

    Notifier.new(url: config.notification_webhook_url).run
  end

  def start_self_deployer!
    return if config.self_update_interval.zero?

    Deployer.new(deployment_name: config.deployment_name,
                 namespace: kubernetes.current_namespace,
                 interval: config.self_update_interval).run
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
