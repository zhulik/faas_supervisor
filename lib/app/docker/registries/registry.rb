# frozen_string_literal: true

class App::Docker::Registries::Registry
  include App

  DEFAULT_HEADERS = {
    Accept: [
      "application/vnd.docker.distribution.manifest.list.v2+json",
      "application/vnd.oci.image.index.v1+json"
    ].freeze
  }.freeze

  def published_digest(name:, tag:)
    connection.get("/v2/#{name}/manifests/#{tag}", {}, DEFAULT_HEADERS.merge(Authorization: "Bearer #{token(name)}"))
              .headers["docker-content-digest"]
  end

  private

  def connection = raise NotImplementedError
  def token(image_name) = raise NotImplementedError

  def configure_connection(faraday)
    faraday.response :raise_error
    faraday.response :json, content_type: /.+/, parser_options: { symbolize_names: true }
  end
end
