# frozen_string_literal: true

class FaasSupervisor::Supervisor
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)

  def run
    scaler.run if function.autoscaling.enabled?
    deployer.run if function.autodeployment.enabled?
    info { "Started" }
  end

  def stop
    scaler.stop if function.autoscaling.enabled?
    deployer.stop if function.autodeployment.enabled?
    info { "Stopped" }
  end

  private

  memoize def scaler = Scaler.new(function:)
  memoize def deployer = Deployer.new(function:)

  def logger_info = "Function = #{function.name.inspect}"
end
