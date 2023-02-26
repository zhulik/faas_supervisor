# frozen_string_literal: true

class FaasSupervisor::Kubernetes::Client
  include FaasSupervisor::Helpers

  SERVICE_ACCOUNT_PATH = "/var/run/secrets/kubernetes.io/serviceaccount"

  TOKEN_PATH = "#{SERVICE_ACCOUNT_PATH}/token".freeze
  CERT_PATH = "#{SERVICE_ACCOUNT_PATH}/ca.crt".freeze
  NAMESPACE_PATH = "#{SERVICE_ACCOUNT_PATH}/namespace".freeze

  option :host, type: T::String
  option :scheme, type: T::Coercible::String

  memoize def current_namespace = read_file(NAMESPACE_PATH) || ENV.fetch("KUBERNETES_NAMESPACE")

  memoize def apps_v1_api = Zilla::AppsV1Api.new(client)
  memoize def core_v1_api = Zilla::CoreV1Api.new(client)

  private

  memoize def client
    info { "Building client for #{scheme}:#{host}, cert_path = #{CERT_PATH}" }

    Zilla::ApiClient.new(config)
  end

  memoize def config
    Zilla::Configuration.new.tap do |cfg|
      cfg.host = host
      cfg.scheme = scheme
      cfg.server_index = nil
      cfg.api_key_prefix["BearerToken"] = "Bearer"

      if token
        cfg.ssl_ca_file = CERT_PATH
        cfg.api_key["BearerToken"] = token
      end
    end
  end

  def token = read_file(TOKEN_PATH)

  def read_file(path)
    File.read(path)
  rescue Errno::ENOENT
    warn { "File #{path} was not found. Not running in kubernetes?" }
    nil
  end
end
