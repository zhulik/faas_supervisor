# frozen_string_literal: true

class FaasSupervisor::ScalingPolicies::Simple < FaasSupervisor::ScalingPolicies::Policy
  private

  def calculate_raw
    sum = summary

    # info("replicas: #{sum.replicas}, available_replicas: #{sum.availableReplicas}")

    [sum.replicas, 1]
  end
end
