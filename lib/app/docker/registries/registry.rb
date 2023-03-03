# frozen_string_literal: true

class App::Docker::Registries::Registry
  include Memery

  DEFAULT_HEADERS = {
    Accept: [
      "application/vnd.docker.distribution.manifest.list.v2+json",
      "application/vnd.oci.image.index.v1+json"
    ].freeze
  }.freeze

  def published_digest(reference)
    raise ArgumentError, "reference must have non-nil tag" if reference.tag.nil?

    connection.get("/v2/#{reference.full_name}/manifests/#{reference.tag}", {},
                   DEFAULT_HEADERS.merge(Authorization: "Bearer #{token(reference)}"))
              .headers["docker-content-digest"]
  end

  private

  memoize def connection
    raise NotImplementedError
  end

  def token(reference) = raise NotImplementedError

  def configure_connection(faraday)
    faraday.response :raise_error
    faraday.response :json, content_type: /.+/, parser_options: { symbolize_names: true }
  end
end
