# frozen_string_literal: true

class FaasSupervisor::Docker::Registries::Registry
  include FaasSupervisor::Helpers

  ACCEPT_HEADERS = [
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.oci.image.index.v1+json"
  ].freeze

  def published_digest(name:, tag:)
    url = "/v2/#{name}/manifests/#{tag}"
    connection.get(url, {},
                   {
                     Authorization: "Bearer #{token(name)}",
                     Accept: ACCEPT_HEADERS
                   }).headers["docker-content-digest"]
  rescue Faraday::Error => e
    warn { url }
    warn { e }
    nil
  end

  private

  def connection = raise NotImplementedError
  def token(image_name) = raise NotImplementedError

  def configure_connection(faraday)
    faraday.response :raise_error
    faraday.response :json, content_type: /.+/, parser_options: { symbolize_names: true }
  end
end
