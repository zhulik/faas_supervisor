# frozen_string_literal: true

class FaasSupervisor::Supervisor
  include FaasSupervisor::Helpers

  option :openfaas, type: T.Instance(FaasSupervisor::Openfaas::Client)
  option :prometheus, type: T.Instance(Prometheus::ApiClient::Client)

  option :function, type: T.Instance(FaasSupervisor::Openfaas::Function)

  def run
    scaler.run
    info { "Started" }
  end

  def stop
    scaler.stop
    info { "Stopped" }
  end

  private

  memoize def scaler = FaasSupervisor::Scaler.new(openfaas:, function:, prometheus:)

  def logger_info = "Function = #{function.name.inspect}"
end
