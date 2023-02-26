# frozen_string_literal: true

class FaasSupervisor::Supervisor
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)
  option :parent, type: T.Interface(:async)

  def run
    scaler.run if function.autoscaling.enabled?
    deployer.run if function.autodeployment.enabled?
    info { "Started" }
  end

  private

  memoize def scaler = Scaler.new(function:, parent:)
  def logger_info = "Function = #{function.name.inspect}"

  memoize def deployer
    Deployer.new(deployment_name: function.name,
                 namespace: function.namespace,
                 interval: function.supervisor_config.autodeployment.interval,
                 parent:)
  end
end
