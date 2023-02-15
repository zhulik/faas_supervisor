# frozen_string_literal: true

class FaasSupervisor::Supervisors
  include FaasSupervisor::Helpers

  inject :metrics_store

  def update(functions)
    functions = functions.group_by(&:name).transform_values(&:first)

    added, updated, deleted = compare(functions)
    added, updated, deleted = apply(added, updated, deleted)

    metrics_store.inc("supervised_functions", added - deleted)

    info { "Added: #{added}, Deleted: #{deleted}, Updated: #{updated}" } if (added + deleted + updated).positive?
    debug { "Total functions supervised: #{storage.count}" }
  end

  def stop = delete_supervision(storage.values.map(&:function))

  private

  memoize def storage = {}

  def compare(functions) # rubocop:disable Metrics/AbcSize
    unsupervised = functions.values.reject(&:supervised?).map(&:name)
    deployed = functions.keys - unsupervised
    known = storage.keys
    updated = (deployed & known).reject { functions[_1].labels == storage[_1].function.labels }
    [
      (deployed - known), # added functions
      updated,
      (known - deployed) + unsupervised # deleted functions
    ].map { functions.values_at(*_1.uniq).compact }
  end

  def add_supervision(functions)
    functions.each do |function|
      storage[function.name] = Supervisor.new(function:).tap(&:run)
    end.count
  end

  def update_supervision(functions)
    delete_supervision(functions)
    add_supervision(functions)
  end

  def delete_supervision(functions)
    functions.select { storage.key?(_1.name) }
             .each { storage.delete(_1.name).tap(&:stop) }
             .count
  end

  def apply(added, updated, deleted)
    deleted = delete_supervision(deleted)
    added = add_supervision(added)
    updated = update_supervision(updated)
    [added, updated, deleted]
  end
end
