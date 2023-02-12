# frozen_string_literal: true

class FaasSupervisor::Scaler
  include FaasSupervisor::Helpers

  option :openfaas, type: T.Instance(FaasSupervisor::Openfaas::Client)
  option :function, type: T.Instance(FaasSupervisor::Openfaas::Function)

  def run
    barrier.async do
      loop do
        debug { "Checking function #{function.name.inspect}" }
        sleep(config.check_every)
      end
    end
    info { "Started for function #{function.name.inspect}" }
  end

  def stop
    barrier.stop
    barrier.wait
    info { "Stopped for function #{function.name.inspect}" }
  end

  private

  def config = function.supervisor_config.autoscaling

  memoize def barrier = Async::Barrier.new
end
