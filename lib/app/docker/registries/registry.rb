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

    throttler.wait
    connection.head("/v2/#{reference.full_name}/manifests/#{reference.tag}", {},
                    DEFAULT_HEADERS.merge(Authorization: "Bearer #{cached_token(reference)}"))
              .headers["docker-content-digest"]
  end

  private

  memoize def throttler = Async::Throttler.new(1, 10)
  memoize def cache = Hash.new { _1[_2] = {} }

  memoize def connection
    raise NotImplementedError
  end

  def cached_token(reference) = with_cache(reference, duration: 50) { token(_1) }

  def with_cache(id, duration:, &)
    existing = cache[id]

    existing[:task]&.wait
    return existing[:value] if existing[:value] && Time.now - existing[:created_at] < duration

    Async { existing.merge!(value: yield(id), created_at: Time.now) }.tap do |task|
      existing[:task] = task
    end
    with_cache(id, duration:, &)
  end

  def token(reference) = raise NotImplementedError

  def configure_connection(faraday)
    faraday.response :raise_error
    faraday.response :json, content_type: /.+/, parser_options: { symbolize_names: true }
  end
end
