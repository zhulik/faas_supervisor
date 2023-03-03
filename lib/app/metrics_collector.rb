# frozen_string_literal: true

class App::MetricsCollector
  include App::Helpers

  inject :bus

  def run
    convert("faas_supervisor.functions.found", "metrics.updated") do |value|
      { functions: { value: } }
    end

    convert("faas_supervisor.supervised_functions.changed", "metrics.updated") do |payload|
      { supervised_functions: { value: payload[:total] } }
    end
  end

  private

  def convert(from_event, to_event) = bus.subscribe(from_event) { bus.publish(to_event, **yield(_1)) }
end
