# frozen_string_literal: true

class FaasSupervisor::Supervisor
  include FaasSupervisor::Helpers

  option :openfaas, type: T.Instance(FaasSupervisor::Openfaas::Client)
  option :function, type: T.Instance(FaasSupervisor::Openfaas::Function)

  def run
    scaler.run
    info { "Started for function #{function.name.inspect}" }
  end

  def stop
    scaler.stop
    info { "Stopped for function #{function.name.inspect}" }
  end

  memoize def scaler = FaasSupervisor::Scaler.new(openfaas:, function:)
end
