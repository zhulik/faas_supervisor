# frozen_string_literal: true

class FaasSupervisor::Scaler
  include FaasSupervisor::Helpers

  option :openfaas, type: T.Instance(FaasSupervisor::Openfaas::Client)
  option :prometheus, type: T.Instance(Prometheus::ApiClient::Client)

  option :function, type: T.Instance(FaasSupervisor::Openfaas::Function)

  def run
    barrier.async do
      loop do
        cycle
        sleep(config.update_interval)
      end
    end
    info { "Started, update interval: #{config.update_interval}" }
  end

  def stop
    barrier.stop
    barrier.wait
    info { "Stopped" }
  end

  private

  memoize def barrier = Async::Barrier.new
  memoize def policy = FaasSupervisor::ScalingPolicies::Simple.new(openfaas:, prometheus:, function:)

  def logger_info = "Function = #{function.name.inspect}"
  def config = function.supervisor_config.autoscaling

  def cycle
    debug { "Checking..." }

    old_scale, new_scale = policy.calculate

    return debug { "No changes in scaling" } if old_scale == new_scale

    info { "Scaling from #{old_scale} to #{new_scale}..." }
  end
end
