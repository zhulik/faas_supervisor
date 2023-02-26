# frozen_string_literal: true

class FaasSupervisor::Config
  include FaasSupervisor::Helpers

  DEFAULT_KUBERNETES_HOST = "127.0.0.1"
  DEFAULT_KUBERNETES_PORT = 8001
  DEFAULT_SELF_UPDATE_INTERVAL = 30

  option :openfaas_url, type: T::String
  option :openfaas_username, type: T::String
  option :openfaas_password, type: T::String

  option :prometheus_url, type: T::String

  option :kubernetes_url, type: T::String
  option :kubernetes_scheme, type: T::Coercible::String

  option :update_interval, type: T::Coercible::Integer, default: -> { 10 }

  option :metrics_server_port, type: T::Coercible::Integer, default: -> { 8080 }

  option :deployment_name, type: T::String, default: -> { "faas-supervisor" }
  option :self_update_interval, type: T::Coercible::Float

  class << self
    def build
      kubernetes_host = ENV.fetch("KUBERNETES_SERVICE_HOST", DEFAULT_KUBERNETES_HOST)
      kubernetes_port = ENV.fetch("KUBERNETES_SERVICE_PORT", DEFAULT_KUBERNETES_PORT)
      self_update_interval = ENV.fetch("SELF_UPDATE_INTERVAL", DEFAULT_SELF_UPDATE_INTERVAL)

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
        self_update_interval:
      )
    end
  end
end
