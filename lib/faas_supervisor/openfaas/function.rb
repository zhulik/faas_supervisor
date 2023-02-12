# frozen_string_literal: true

class FaasSupervisor::Openfaas::Function < Dry::Struct
  include Memery

  T = Dry.Types

  KV = T::Hash.map(T::Coercible::String, T::String)

  attribute :name, T::String
  attribute :namespace, T::String

  attribute? :invocationCount, T::Integer # For some reason OpenFaas does not return it for some functions

  attribute :image, T::String
  attribute :replicas, T::Integer
  attribute :availableReplicas, T::Integer

  attribute :labels, KV
  attribute :annotations, KV

  attribute :createdAt, T::JSON::DateTime

  memoize def supervisor_config = FaasSupervisor::Openfaas::SupervisorConfig.new(labels)

  def supervised? = supervisor_config.enabled?
end
