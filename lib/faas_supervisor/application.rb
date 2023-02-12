# frozen_string_literal: true

class FaasSupervisor::Application
  include FaasSupervisor::Helpers

  option :openfaas_url, type: T::String
  option :openfaas_username, type: T::String
  option :openfaas_password, type: T::String
  option :update_every, type: T::Coercible::Integer, default: -> { 10 }

  option :prometheus_url, type: T::String

  def run
    loop do
      functions = openfaas.functions # TODO: timeout
      info { "Functions found: #{functions.count}" }

      update_supervisors(functions)

      info { "Total functions supervised: #{supervisors.count}" }

      sleep(update_every)
    end
  end

  private

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

    info { "Added: #{added}, Deleted: #{deleted}, Updated: #{updated}" }
  end

  def compare_with_deployed(functions) # rubocop:disable Metrics/AbcSize
    unsupervised = functions.values.reject(&:supervised?).map(&:name)
    deployed = functions.keys - unsupervised
    known = supervisors.keys
    updated = (deployed & known).reject { functions[_1].supervisor_config == supervisors[_1].config }
    [
      (deployed - known), # added functions
      updated,
      (known - deployed) + unsupervised # deleted functions
    ].map { functions.values_at(*_1.uniq).compact }
  end

  def add_supervision(functions)
    return 0 if functions.empty?

    functions.each do |function|
      supervisors[function.name] = FaasSupervisor::Supervisor.new(name: function.name,
                                                                  client: openfaas,
                                                                  config: function.supervisor_config).tap(&:run)
    end.count
  end

  def update_supervision(functions)
    return 0 if functions.empty?

    delete_supervision(functions)
    add_supervision(functions)
  end

  def delete_supervision(functions)
    functions = functions.select { supervisors.key?(_1.name) }
    return 0 if functions.empty?

    functions.each do |function|
      supervisors.delete(function.name).tap(&:stop)
    end.count
  end
end
