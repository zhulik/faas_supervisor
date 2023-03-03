# frozen_string_literal: true

class App::Metrics::Server
  extend Dry::Initializer

  include App::Helpers

  inject :bus

  PATHS = ["/metrics", "/metrics/"].freeze

  NOT_FOUND = Protocol::HTTP::Response[404, {}, ["Not found"]].freeze

  option :prefix, type: T::StringLike.constrained(min_size: 1)

  option :port, type: T::Strict::Integer

  def run
    subscribe_to_metrics!

    endpoint = Async::HTTP::Endpoint.parse("http://0.0.0.0:#{port}")
    Async { Async::HTTP::Server.new(self, endpoint).run }
    info { "Started on #{endpoint.url}" }
  end

  def call(request)
    return NOT_FOUND unless PATHS.include?(request.path)

    Protocol::HTTP::Response[200, {}, serializer.serialize(metrics_store)]
  end

  private

  memoize def metrics_store = Metrics::Store.new

  def subscribe_to_metrics!
    bus.subscribe("metrics.updated") do |metrics|
      metrics.each { metrics_store.set(_1, **_2) }
    end
  end

  memoize def serializer = Metrics::Serializer.new(prefix:)
end
