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
        cycle
        sleep(update_interval)
      end
    end
    info { "Started, update interval: #{update_interval}" }
  end

  def stop
    barrier.stop
    barrier.wait
    delete_supervision(supervisors.values.map(&:function))
  end

  def wait = barrier.wait

  private

  memoize def barrier = Async::Barrier.new
  memoize def supervisors = {}
  memoize def prometheus = Prometheus::ApiClient.client(url: prometheus_url)

  memoize def openfaas
    FaasSupervisor::Openfaas::Client.new(url: openfaas_url,
                                         username: openfaas_username,
                                         password: openfaas_password)
  end

  def set_traps!
    trap("INT") do
      force_exit if @stopping
      @stopping = true
      warn("Interrupted, stopping. Press ^C once more to force exit.")
      stop
    end
  end

  def cycle
    functions = openfaas.functions # TODO: timeout
    debug { "Functions found: #{functions.count}" }

    update_supervisors(functions)
  end

  def update_supervisors(functions)
    functions = functions.group_by(&:name).transform_values(&:first)

    added, updated, deleted = compare_with_deployed(functions)

    deleted = delete_supervision(deleted)
    added = add_supervision(added)
    updated = update_supervision(updated)

    info { "Added: #{added}, Deleted: #{deleted}, Updated: #{updated}" } if (added + deleted + updated).positive?
    debug { "Total functions supervised: #{supervisors.count}" }
  end

  def compare_with_deployed(functions) # rubocop:disable Metrics/AbcSize
    unsupervised = functions.values.reject(&:supervised?).map(&:name)
    deployed = functions.keys - unsupervised
    known = supervisors.keys
    updated = (deployed & known).reject { functions[_1] == supervisors[_1].function }
    [
      (deployed - known), # added functions
      updated,
      (known - deployed) + unsupervised # deleted functions
    ].map { functions.values_at(*_1.uniq).compact }
  end

  def add_supervision(functions)
    functions.each do |function|
      supervisors[function.name] = FaasSupervisor::Supervisor.new(function:, openfaas:, prometheus:).tap(&:run)
    end.count
  end

  def update_supervision(functions)
    delete_supervision(functions)
    add_supervision(functions)
  end

  def delete_supervision(functions)
    functions.select { supervisors.key?(_1.name) }
             .each { supervisors.delete(_1.name).tap(&:stop) }
             .count
  end

  def force_exit
    fatal("Forced exit")
    exit(1)
  end
end
