# frozen_string_literal: true

class App::MetricsCollector
  include Async::App::Component

  def run
    bus.convert("faas_supervisor.functions.found", "metrics.updated") do |value|
      { functions: { value: } }
    end

    bus.convert("faas_supervisor.supervised_functions.changed", "metrics.updated") do |payload|
      { supervised_functions: { value: payload[:total] } }
    end
  end
end
