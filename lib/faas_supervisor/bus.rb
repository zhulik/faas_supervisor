# frozen_string_literal: true

class FaasSupervisor::Bus
  include Dry::Events::Publisher[:faas_supervisor]

  module Publisher
    private

    def publish_event(name, *args, **params)
      payload = args.first || params
      bus = FaasSupervisor::Application.instance.container[:bus]
      bus.register_event(name)
      event = Event.new(name:, payload:, publisher: self)
      bus.publish(name, event:)
    end
  end

  module Subscriber
    private

    def subscribe_event(name)
      bus = FaasSupervisor::Application.instance.container[:bus]
      bus.register_event(name)
      bus.subscribe(name) do |event|
        yield event[:event]
      end
    end
  end

  class Event < FaasSupervisor::Struct
    attribute :name, T::StringLike
    attribute :publisher, T::Instance(Publisher)
    attribute :payload, T::Any
  end
end
