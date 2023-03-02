# frozen_string_literal: true

class App::Bus
  include Dry::Events::Publisher[:faas_supervisor]

  module Publisher
    private

    def publish_event(name, *args, **params)
      payload = args.first || params
      bus = App::Application.instance.container[:bus]
      bus.register_event(name)
      event = Event.new(name:, payload:, publisher: self)
      bus.publish(name, event:)
    end
  end

  module Subscriber
    private

    def subscribe_event(name)
      bus = App::Application.instance.container[:bus]
      bus.register_event(name)
      bus.subscribe(name) do |event|
        yield event[:event]
      end
    end
  end

  class Event < App::Struct
    attribute :name, T::StringLike
    attribute :publisher, T::Instance(Publisher)
    attribute :payload, T::Any
  end
end