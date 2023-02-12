# frozen_string_literal: true

class FaasSupervisor::Supervisor
  include FaasSupervisor::Helpers

  option :name, type: T::String
  option :client, type: T.Instance(FaasSupervisor::Openfaas::Client)
  option :config, type: T.Instance(FaasSupervisor::Openfaas::SupervisorConfig)

  def run
    self
  end

  def stop
    self
  end
end
