# frozen_string_literal: true

class FaasSupervisor::Metrics::Server
  include FaasSupervisor::Helpers
  include Bus::Subscriber

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
    subscribe_event("metrics.updated") do |event|
      event.payload.each { metrics_store.set(_1, **_2) }
    end
  end

  memoize def serializer = Metrics::Serializer.new(prefix:)
end
