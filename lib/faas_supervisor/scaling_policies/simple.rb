# frozen_string_literal: true

class FaasSupervisor::ScalingPolicies::Simple < FaasSupervisor::ScalingPolicies::Policy
  private

  def calculate_raw
    sum, pres = fetch_sum_pres

    if pres.nil? || pres == "NaN" || pres.include?("Inf")
      debug { "Pressure is #{pres.inspect}, no change to scaling" }
      return [sum.replicas, sum.replicas]
    end

    factor = pres.to_f > 1 ? 1 : -1

    [sum.replicas, sum.replicas + factor]
  end

  memoize def pressure_query
    <<~QUERY
      max(rate(gateway_function_invocation_started{function_name=#{function_name}}[#{range}s])) /
        max(rate(gateway_function_invocation_total{function_name=#{function_name},code="200"}[#{range}s]))
    QUERY
  end

  def fetch_sum_pres = [parent.async { summary }, parent.async { pressure }].map(&:wait)

  def pressure = prometheus.query(query: pressure_query).dig("result", 0, "value", 1)

  def function_name = "'#{function.name}.openfaas'"

  def range = config.update_interval * 5
end
