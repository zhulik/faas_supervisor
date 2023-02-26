# frozen_string_literal: true

class FaasSupervisor::FunctionListener
  include FaasSupervisor::Helpers

  option :parent, type: T.Interface(:async)
  option :update_interval, type: T::Coercible::Float

  inject :openfaas
  inject :metrics_store

  def run
    Async::Timer.new(update_interval, run_on_start: true, parent:, call: self)
    info { "Started, update interval: #{update_interval}" }
  end

  # TODO: add timeout
  def call
    functions = openfaas.functions
    debug { "Functions found: #{functions.count}" }

    metrics_store.set("functions", functions.count)

    supervisors.update(functions)
  rescue StandardError => e
    warn(e)
  end

  private

  memoize def supervisors = Supervisors.new(parent:)
end
