# frozen_string_literal: true

class App::Container
  include App

  include Dry::Container::Mixin

  def initialize(config)
    {
      openfaas: Openfaas::Client.new(url: config.openfaas_url,
                                     username: config.openfaas_username,
                                     password: config.openfaas_password),
      kubernetes: Kubernetes::Client.new(host: config.kubernetes_url,
                                         scheme: config.kubernetes_scheme),
      prometheus: ::Prometheus::ApiClient.client(url: config.prometheus_url),
      bus: Bus.new
    }.each { register(_1, _2) }
  end
end
