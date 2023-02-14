# frozen_string_literal: true

class FaasSupervisor::Supervisor
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)

  def run
    scaler.run
    info { "Started" }
  end

  def stop
    scaler.stop
    info { "Stopped" }
  end

  private

  memoize def scaler = Scaler.new(function:)

  def logger_info = "Function = #{function.name.inspect}"
end
