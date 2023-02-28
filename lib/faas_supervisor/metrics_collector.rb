# frozen_string_literal: true

class FaasSupervisor::MetricsCollector
  include FaasSupervisor::Helpers

  include Bus::Publisher
  include Bus::Subscriber

  def run
    convert("faas_supervisor.functions.found", "metrics.updated") do |value|
      { functions: { value: } }
    end

    convert("faas_supervisor.supervised_functions.changed", "metrics.updated") do |payload|
      { supervised_functions: { value: payload[:total] } }
    end
  end

  private

  def convert(from_event, to_event) = subscribe_event(from_event) { publish_event(to_event, **yield(_1.payload)) }
end
