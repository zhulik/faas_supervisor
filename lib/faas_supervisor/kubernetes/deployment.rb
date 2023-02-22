# frozen_string_literal: true

class FaasSupervisor::Kubernetes::Deployment < Dry::Struct
  transform_keys(&:to_sym) # TODO: symbolize names in zilla

  # TODO: DRY
  T = Dry.Types
  KV = T::Hash.map(T::Coercible::String, T::String)

  class Metadata < Dry::Struct
    transform_keys(&:to_sym)

    attribute :name, T::String
    attribute :namespace, T::String
  end

  class Spec < Dry::Struct
    transform_keys(&:to_sym)

    class Selector < Dry::Struct
      transform_keys(&:to_sym)

      attribute :matchLabels, KV
    end

    attribute :selector, Selector
  end

  attribute :kind, T::String
  attribute :apiVersion, T::String
  attribute :metadata, Metadata
  attribute :spec, Spec

  # def initialize(*args, **params)
  #   binding.irb
  # end
end
