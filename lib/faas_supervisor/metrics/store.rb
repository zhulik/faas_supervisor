# frozen_string_literal: true

class FaasSupervisor::Metrics::Store
  include FaasSupervisor::Helpers

  include Enumerable

  Name = T::String.constrained(min_size: 1)

  def inc(name, n = 1, suffix: "total", **tags)
    validate_metric!(name, suffix, tags)
    key = [name, tags]

    counters[key] ||= { name:, tags:, suffix:, value: 0 }
    counters[key][:value] += n
  end

  def set(name, value, suffix: "total", **tags)
    validate_metric!(name, suffix, tags)
    key = [name, tags]
    counters[key] ||= { name:, tags:, suffix:, value: }
    counters[key].merge!(value:)
  end

  def each(&) = counters.values.each(&)

  private

  memoize def counters = {}

  def validate_metric!(name, suffix, tags)
    raise ArgumentError, "Metric name must be a non-empty string" unless Name.valid?(name)
    raise ArgumentError, "Suffix name must be a non-empty string" unless Name.valid?(suffix)

    tags.each do |k, v|
      raise ArgumentError, "Tag name must be a non-empty string" unless Name.valid?(k)
      raise ArgumentError, "Tag value must be a non-empty string" unless Name.valid?(v)
    end
  end
end
