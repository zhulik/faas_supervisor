# frozen_string_literal: true

class App::FunctionListener
  extend Dry::Initializer

  include App::Helpers

  option :update_interval, type: T::Coercible::Float

  inject :openfaas
  inject :bus

  def run
    Async::Timer.new(update_interval, run_on_start: true, call: self, on_error: ->(e) { warn(e) })
    info { "Started, update interval: #{update_interval}" }
  end

  # TODO: add timeout
  def call
    functions = openfaas.functions
    debug { "Functions found: #{functions.count}" }

    bus.publish("faas_supervisor.functions.found", functions.count)

    supervisors.update(functions)
  end

  private

  memoize def supervisors = Supervisors.new
end
