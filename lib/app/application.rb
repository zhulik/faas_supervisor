# frozen_string_literal: true

class App::Application < Async::App
  include App

  inject :kubernetes

  def container_config
    {
      openfaas: Openfaas::Client.new(url: config.openfaas_url,
                                     username: config.openfaas_username,
                                     password: config.openfaas_password),
      kubernetes: Kubernetes::Client.new(host: config.kubernetes_url,
                                         scheme: config.kubernetes_scheme),
      prometheus: ::Prometheus::ApiClient.client(url: config.prometheus_url)
    }
  end

  def run!
    start_notifier!

    start_metrics_collector!
    start_function_listener!
    start_self_deployer!
  end

  private

  def app_name = :faas_supervisor

  memoize def config = Config.build

  def start_function_listener! = FunctionListener.new(update_interval: config.update_interval).run
  def start_metrics_collector! = MetricsCollector.new.run

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
end
