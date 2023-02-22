# frozen_string_literal: true

class FaasSupervisor::Kubernetes::Client
  include FaasSupervisor::Helpers

  INPUT = "#{__dir__}/../../../data/swagger.json".freeze

  SERVICE_ACCOUNT_PATH = "/var/run/secrets/kubernetes.io/serviceaccount"
  TOKEN_PATH = "#{SERVICE_ACCOUNT_PATH}/token".freeze
  CERT_PATH = "#{SERVICE_ACCOUNT_PATH}/ca.crt".freeze
  NAMESPACE_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/namespace"

  option :host, type: T::String
  option :scheme, type: T::Coercible::String

  memoize def client
    info { "Building client for #{scheme}:#{host}, cert_path = #{CERT_PATH}" }

    Zilla.for(INPUT, host:, scheme:, faraday_config: { ssl: { ca_file: CERT_PATH } }) do |f, _target|
      f.request(:authorization, :Bearer, token) unless token.nil?
    end
  end

  def all_pods = client.listCoreV1PodForAllNamespaces["items"]
  def all_deployments = client.listAppsV1DeploymentForAllNamespaces["items"].map { Kubernetes::Deployment.new(_1) }
  def token = read_file(TOKEN_PATH)
  def current_namespace = read_file(NAMESPACE_PATH)

  def deployments(namespace = current_namespace)
    client.listAppsV1NamespacedDeployment(namespace)["items"].map { Kubernetes::Deployment.new(_1) }
  end

  def deployment(name, namespace = current_namespace)
    client.readAppsV1NamespacedDeployment(namespace, name).then { Kubernetes::Deployment.new(_1) }
  end

  def read_file(path)
    File.read(path)
  rescue Errno::ENOENT
    warn { "File #{path} was not found. Not running in kubernetes?" }
  end
end
