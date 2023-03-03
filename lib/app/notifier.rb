# frozen_string_literal: true

class App::Notifier
  extend Dry::Initializer

  include App

  option :url, type: T::Strict::String

  def run
    bus.async_subscribe("kubernetes.application.published_image_updated") do |event|
      send_notification(event, "is about to be restarted")
    end

    bus.async_subscribe("kubernetes.application.restarted") do |event|
      send_notification(event, "has been restarted!")
    end
  end

  private

  def send_notification(event, message)
    header = "FaasSupervisor:\n\n#{event[:kind]} *#{event[:namespace]}/#{event[:name]}*"
    connection.post("", { text: "#{header}\n#{message}" })
  end

  memoize def connection
    Faraday.new(url) do |f|
      f.request :json
      f.response :raise_error
      f.response :json
    end
  end
end
