# frozen_string_literal: true

class FaasSupervisor::Application
  include FaasSupervisor::Helpers

  option :openfaas_url, type: T::String
  option :openfaas_username, type: T::String
  option :openfaas_password, type: T::String
  option :update_every, type: T::Coercible::Integer, default: -> { 10 }

  option :prometheus_url, type: T::String

  def run
    barrier.async do
      loop do
        functions = openfaas.functions # TODO: timeout
        debug { "Functions found: #{functions.count}" }

        update_supervisors(functions)

        debug { "Total functions supervised: #{supervisors.count}" }

        sleep(update_every)
      end
    end
    info { "Started" }
  end

  def stop
    barrier.stop
    barrier.wait
  end

  private

  memoize def barrier = Async::Barrier.new
  memoize def supervisors = {}

  memoize def openfaas
    FaasSupervisor::Openfaas::Client.new(url: openfaas_url,
                                         username: openfaas_username,
                                         password: openfaas_password)
  end

  def update_supervisors(functions)
    functions = functions.group_by(&:name).transform_values(&:first)

    added, updated, deleted = compare_with_deployed(functions)

    deleted = delete_supervision(deleted)
    added = add_supervision(added)
    updated = update_supervision(updated)

    info { "Added: #{added}, Deleted: #{deleted}, Updated: #{updated}" } if (added + deleted + updated).positive?
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
      supervisors[function.name] = FaasSupervisor::Supervisor.new(function:, openfaas:).tap(&:run)
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
end
