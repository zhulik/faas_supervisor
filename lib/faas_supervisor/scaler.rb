# frozen_string_literal: true

class FaasSupervisor::Scaler
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)

  def run
    timer.start
    info { "Started, update interval: #{config.update_interval}" }
  end

  def stop
    timer.stop
    info { "Stopped" }
  end

  private

  memoize def timer = Async::Timer.new(config.update_interval, start: false, run_on_start: true) { cycle }
  memoize def policy = FaasSupervisor::ScalingPolicies::Simple.new(function:)

  def logger_info = "Function = #{function.name.inspect}"
  def config = function.supervisor_config.autoscaling

  # TODO: add timeout
  # TODO: handle errors
  def cycle
    debug { "Checking..." }

    old_scale, new_scale = policy.calculate

    return debug { "No changes in scaling" } if old_scale == new_scale

    info { "Scaling from #{old_scale} to #{new_scale}..." }
  end
end
