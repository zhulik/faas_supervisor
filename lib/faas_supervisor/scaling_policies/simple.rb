# frozen_string_literal: true

class FaasSupervisor::ScalingPolicies::Simple < FaasSupervisor::ScalingPolicies::Policy
  private

  def calculate_raw
    sum, pres = [Async { summary }, Async { pressure }].map(&:wait)

    if pres == "NaN"
      debug { "Pressure is NaN, no executions?" }
      return [sum.replicas, 1]
    end
    debug { "pressure: #{pres}" }

    [sum.replicas, 1]
  end

  memoize def pressure_query
    <<~QUERY
      max(rate(gateway_function_invocation_started{function_name=#{function_name}}[#{range}s])) /
        max(rate(gateway_function_invocation_total{function_name=#{function_name}}[#{range}s]))
    QUERY
  end

  def pressure = prometheus.query(query: pressure_query).dig("result", 0, "value", 1)

  def function_name = "'#{function.name}.openfaas'"

  def range = config.update_interval * 5
end
