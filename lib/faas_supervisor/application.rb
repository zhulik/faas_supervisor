# frozen_string_literal: true

class FaasSupervisor::Application
  include FaasSupervisor::Helpers

  option :openfaas_url, type: T::String
  option :openfaas_username, type: T::String
  option :openfaas_password, type: T::String

  option :prometheus_url, type: T::String

  option :update_interval, type: T::Coercible::Integer, default: -> { 10 }

  inject :openfaas

  class << self
    def instance = @@instance

    def [](key) = instance[key]
  end

  def initialize(*, **)
    super(*, **)
    @@instance = self # rubocop:disable Style/ClassVars
  end

  def [](key) = container[key]

  def run
    set_traps!
    init_container!

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
  memoize def supervisors = Supervisors.new
  memoize def container = Dry::Container.new

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

  def init_container!
    container.register(:openfaas, Openfaas::Client.new(url: openfaas_url,
                                                       username: openfaas_username,
                                                       password: openfaas_password))
    container.register(:prometheus, Prometheus::ApiClient.client(url: prometheus_url))
  end
end
