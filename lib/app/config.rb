# frozen_string_literal: true

class App::Config < App::Struct
  DEFAULT_KUBERNETES_HOST = "127.0.0.1"

  attribute :openfaas_url, T::Strict::String
  attribute :openfaas_username, T::Strict::String
  attribute :openfaas_password, T::Strict::String

  attribute :prometheus_url, T::Strict::String

  attribute :kubernetes_url, T::Strict::String
  attribute :kubernetes_scheme, T::StringLike

  attribute :update_interval, T::Coercible::Float.default(10)
  attribute :self_update_interval, T::Coercible::Float

  attribute :metrics_server_port, T::Coercible::Integer.default(8080)

  attribute :deployment_name, T::Strict::String.default("faas-supervisor")

  attribute :notification_webhook_url, T::Strict::String.optional

  class << self
    def build
      kubernetes_host = ENV.fetch("KUBERNETES_SERVICE_HOST", DEFAULT_KUBERNETES_HOST)
      kubernetes_port = ENV.fetch("KUBERNETES_SERVICE_PORT", 8001)
      kubernetes_scheme = kubernetes_host == DEFAULT_KUBERNETES_HOST ? :http : :https

      new(
        openfaas_url: ENV.fetch("OPENFAAS_URL"),
        openfaas_username: ENV.fetch("OPENFAAS_USERNAME"),
        openfaas_password: ENV.fetch("OPENFAAS_PASSWORD"),

        prometheus_url: ENV.fetch("PROMETHEUS_URL", "http://127.0.0.1:9090"),

        update_interval: ENV.fetch("SUPERVISOR_UPDATE_INTERVAL", "10"),

        metrics_server_port: ENV.fetch("SUPERVISOR_METRICS_SERVER_PORT", "8080"),
        kubernetes_url: "#{kubernetes_host}:#{kubernetes_port}",
        kubernetes_scheme:,
        self_update_interval: ENV.fetch("SELF_UPDATE_INTERVAL", 30),
        notification_webhook_url: ENV.fetch("NOTIFICATION_WEBHOOK_URL", nil)
      )
    end
  end
end
