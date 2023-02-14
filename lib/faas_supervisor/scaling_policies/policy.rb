# frozen_string_literal: true

class FaasSupervisor::ScalingPolicies::Policy
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)

  inject :openfaas
  inject :prometheus

  # returns two numbers: current scale and desired scale
  def calculate = calculate_raw.tap { [_1, normalize(_2)] }

  private

  def calculate_raw = NotImplementedError
  def logger_info = "Function = #{function.name.inspect}"

  def config = function.supervisor_config.autoscaling
  def summary = openfaas.function(function.name)

  def normalize(value)
    return config.min if value < config.min
    return config.max if value > config.max

    value
  end
end
