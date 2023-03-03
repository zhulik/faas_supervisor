# frozen_string_literal: true

class App::Supervisor
  extend Dry::Initializer

  include App

  option :function, type: T.Instance(Openfaas::Function)

  def run
    scaler.run if function.autoscaling.enabled?
    deployer.run if function.autodeployment.enabled?
    info { "Started" }
  end

  private

  memoize def scaler = Scaler.new(function:)
  def logger_info = "Function = #{function.name.inspect}"

  memoize def deployer
    Deployer.new(deployment_name: function.name,
                 namespace: function.namespace,
                 interval: function.supervisor_config.autodeployment.interval)
  end
end
