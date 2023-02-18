# frozen_string_literal: true

class FaasSupervisor::Metrics::Server
  include FaasSupervisor::Helpers

  PATHS = ["/metrics", "/metrics/"].freeze

  NOT_FOUND = Protocol::HTTP::Response[404, {}, ["Not found"]].freeze

  option :port, type: T::Integer

  inject :metrics_store

  def run
    endpoint = Async::HTTP::Endpoint.parse("http://0.0.0.0:#{port}")
    @task = Async { Async::HTTP::Server.new(self, endpoint).run }
    info { "Started on #{endpoint.url}" }
  end

  def call(request)
    return NOT_FOUND unless PATHS.include?(request.path)

    Protocol::HTTP::Response[200, {}, serializer.serialize(metrics_store)]
  end

  def stop
    @task.stop
    @task.wait
    info { "Stopped" }
  end

  private

  memoize def serializer = Metrics::Serializer.new
end
