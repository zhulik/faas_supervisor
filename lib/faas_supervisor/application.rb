# frozen_string_literal: true

class FaasSupervisor::Application
  include FaasSupervisor::Helpers

  option :openfaas_url, type: T::String
  option :openfaas_username, type: T::String
  option :openfaas_password, type: T::String

  option :prometheus_url, type: T::String

  option :update_interval, type: T::Coercible::Integer, default: -> { 10 }

  def run
    set_traps!

    barrier.async do
      loop do
        cycle # TODO: timeout
        sleep(update_interval)
      end
    end
    info { "Started, update interval: #{update_interval}" }
  end

  def stop
    barrier.stop
    barrier.wait
    supervisors.stop
  end

  def wait = barrier.wait

  private

  memoize def barrier = Async::Barrier.new
  memoize def supervisors = Supervisors.new(openfaas:, prometheus:)
  memoize def prometheus = Prometheus::ApiClient.client(url: prometheus_url)

  memoize def openfaas
    Openfaas::Client.new(url: openfaas_url,
                         username: openfaas_username,
                         password: openfaas_password)
  end

  def set_traps!
    trap("INT") do
      force_exit if @stopping
      @stopping = true
      warn { "Interrupted, stopping. Press ^C once more to force exit." }
      stop
    end
  end

  def cycle
    functions = openfaas.functions
    debug { "Functions found: #{functions.count}" }

    supervisors.update(functions)
  end

  def force_exit
    fatal { "Forced exit" }
    exit(1)
  end
end
