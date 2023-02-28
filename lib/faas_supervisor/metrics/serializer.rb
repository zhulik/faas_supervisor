# frozen_string_literal: true

class FaasSupervisor::Metrics::Serializer
  include FaasSupervisor::Helpers

  option :prefix, type: T::StringLike

  def serialize(metrics)
    metrics.flat_map { metric_line(_1) }
           .compact
           .join("\n")
           .then { "#{_1}\n" }
  end

  def metric_name(value) = "#{prefix}_#{value[:name]}_#{value[:suffix]}"

  def metric_labels(value) = value[:labels].map { |tag, tag_value| "#{tag}=#{tag_value.to_s.inspect}" }.join(",")

  def metric_line(value)
    labels = metric_labels(value)

    "#{metric_name(value)}{#{labels}} #{value[:value]}" if value.key?(:value)
  end
end
