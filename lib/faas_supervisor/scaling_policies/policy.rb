# frozen_string_literal: true

class FaasSupervisor::ScalingPolicies::Policy
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)

  inject :openfaas
  inject :prometheus

  # returns two numbers: current scale and desired scale
  def calculate
    calculate_raw.then { [_1, _2.clamp(config.min, config.max)] }
  end

  private

  def calculate_raw = NotImplementedError
  def logger_info = "Function = #{function.name.inspect}"

  def config = function.supervisor_config.autoscaling
  def summary = openfaas.function(function.name)
end
