# frozen_string_literal: true

class FaasSupervisor::Scaler
  include FaasSupervisor::Helpers

  option :openfaas, type: T.Instance(FaasSupervisor::Openfaas::Client)
  option :function, type: T.Instance(FaasSupervisor::Openfaas::Function)

  def run
    barrier.async { loop { cycle } }
    info { "Started for function #{function.name.inspect}, update interval: #{config.update_interval}" }
  end

  def stop
    barrier.stop
    barrier.wait
    info { "Stopped for function #{function.name.inspect}" }
  end

  private

  memoize def barrier = Async::Barrier.new

  def config = function.supervisor_config.autoscaling

  def cycle
    debug { "Checking function #{function.name.inspect}" }

    sum = summary

    debug { JSON.pretty_generate(sum.attributes) }
    sleep(config.update_interval)
  end

  def summary = openfaas.function(function.name)
end
