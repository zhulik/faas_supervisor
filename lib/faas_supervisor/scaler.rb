# frozen_string_literal: true

class FaasSupervisor::Scaler
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)

  inject :openfaas

  def run
    Async::Timer.new(config.update_interval, run_on_start: true, call: self)
    info { "Started, update interval: #{config.update_interval}" }
  end

  # TODO: add timeout
  def call
    debug { "Checking..." }

    old_scale, new_scale = policy.calculate

    return debug { "No changes in scaling" } if old_scale == new_scale

    info { "Scaling from #{old_scale} to #{new_scale}..." }
    # openfaas.scale(function.name, new_scale)
  rescue StandardError => e
    warn(e)
  end

  private

  memoize def policy = ScalingPolicies::Simple.new(function:)

  def logger_info = "Function = #{function.name.inspect}"
  def config = function.supervisor_config.autoscaling
end
