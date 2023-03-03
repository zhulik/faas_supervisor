# frozen_string_literal: true

class App::Metrics::Store
  include App

  include Enumerable

  def set(name, value:, suffix: "total", **labels)
    validate_metric!(name, suffix, labels)
    key = [name, labels]
    counters[key] ||= { name:, labels:, suffix:, value: }
    counters[key].merge!(value:)
  end

  def each(&) = counters.values.each(&)

  private

  memoize def counters = {}

  def validate_metric!(name, suffix, labels)
    value = T::StringLike.constrained(min_size: 1)
    raise ArgumentError, "Metric name must be a non-empty string" unless value.valid?(name)
    raise ArgumentError, "Suffix name must be a non-empty string" unless value.valid?(suffix)

    labels.each do |k, v|
      raise ArgumentError, "Tag name must be a non-empty string" unless value.valid?(k)
      raise ArgumentError, "Tag value must be a non-empty string" unless value.valid?(v)
    end
  end
end
