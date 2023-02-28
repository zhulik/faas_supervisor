# frozen_string_literal: true

class App::Notifier
  include App::Helpers
  include Bus::Subscriber

  option :url, type: T::Strict::String

  def run
    subscribe_event("kubernetes.application.published_image_updated") do |event|
      send_notification(event, "is about to be restarted")
    end

    subscribe_event("kubernetes.application.restarted") do |event|
      send_notification(event, "has been restarted!")
    end
  end

  private

  def send_notification(event, message)
    payload = event.payload
    header = "FaasSupervisor:\n\n#{payload[:kind]} *#{payload[:namespace]}/#{payload[:name]}*"
    Async { connection.post("", { text: "#{header}\n#{message}" }) }
  end

  memoize def connection
    Faraday.new(url) do |f|
      f.request :json
      f.response :raise_error
      f.response :json
    end
  end
end
