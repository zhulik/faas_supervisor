# frozen_string_literal: true

class FaasSupervisor::Openfaas::SupervisorConfig < Dry::Struct
  T = Dry.Types

  class AutoscalingConfig < Dry::Struct
    attribute :enabled, T::Params::Bool.default(false)

    attribute :update_interval, T::Coercible::Integer.default(10)

    attribute :max, T::Coercible::Integer.default(20)
    attribute :min, T::Coercible::Integer.default(1)

    def enabled? = enabled
  end

  attribute :enabled, T::Params::Bool.default(false)

  attribute :autoscaling, AutoscalingConfig.default(AutoscalingConfig.new.freeze)

  def self.new(labels)
    super(labels.each_with_object({}) do |(k, v), acc|
      head, *tail = k.split(".")

      next if head != "supervisor"

      tail.each.with_index.reduce(acc) do |nested, (part, index)|
        nested[part.to_sym] ||= {}.then { index == tail.count - 1 ? v : _1 }
      end
    end)
  end

  def enabled? = enabled
end
