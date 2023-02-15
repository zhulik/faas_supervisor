# frozen_string_literal: true

class FaasSupervisor::Metrics::Serializer
  def serialize(metrics)
    metrics.flat_map { metric_line(_1) }
           .compact
           .join("\n")
           .then { "#{_1}\n" }
  end

  def metric_name(value) = "faas_supervisor_#{value[:name]}_#{value[:suffix]}"

  def metric_tags(value) = value[:tags].map { |tag, tag_value| "#{tag}=#{tag_value.to_s.inspect}" }.join(",")

  def metric_line(value)
    tags = metric_tags(value)

    "#{metric_name(value)}{#{tags}} #{value[:value]}" if value.key?(:value)
  end
end
