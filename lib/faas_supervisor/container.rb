# frozen_string_literal: true

class FaasSupervisor::Container
  include FaasSupervisor

  include Dry::Container::Mixin

  def initialize(config)
    register(:openfaas, Openfaas::Client.new(url: config.openfaas_url,
                                             username: config.openfaas_username,
                                             password: config.openfaas_password))
    register(:kubernetes, Kubernetes::Client.new(host: config.kubernetes_url,
                                                 scheme: config.kubernetes_scheme))
    register(:prometheus, ::Prometheus::ApiClient.client(url: config.prometheus_url))
    register(:metrics_store, Metrics::Store.new)
    register(:bus, Async::Bus.get)
  end
end
