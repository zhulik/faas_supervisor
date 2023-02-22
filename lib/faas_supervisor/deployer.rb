# frozen_string_literal: true

class FaasSupervisor::Deployer
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)
  inject :kubernetes

  def run
    timer.start
    info { "Started, update interval: #{config.interval}" }
  end

  def stop
    timer.stop
    info { "Stopped" }
  end

  private

  memoize def timer = Async::Timer.new(config.interval, start: false, run_on_start: true) { cycle }

  def logger_info = "Function = #{function.name.inspect}"
  def config = function.supervisor_config.autodeployment

  # TODO: add timeout
  def cycle
    debug { "Checking..." }
    info { kubernetes.deployment(function.name, "openfaas").spec.selector.matchLabels.pretty_inspect }
  rescue StandardError => e
    warn(e)
  end
end
