# frozen_string_literal: true

class FaasSupervisor::Openfaas::Function < FaasSupervisor::Struct
  KV = T::Hash.map(T::Coercible::String, T::Strict::String)

  attribute :name, T::Strict::String
  attribute :namespace, T::Strict::String

  attribute? :invocationCount, T::Strict::Integer # For some reason OpenFaas does not return it for some functions

  attribute :image, T::Strict::String
  attribute :replicas, T::Strict::Integer
  attribute? :availableReplicas, T::Strict::Integer # For some reason OpenFaas does not return it for some functions

  attribute :labels, KV
  attribute :annotations, KV

  attribute :createdAt, T::JSON::DateTime

  memoize def supervisor_config = Openfaas::SupervisorConfig.new(labels)

  def supervised? = supervisor_config.enabled?
  def autoscaling = supervisor_config.autoscaling
  def autodeployment = supervisor_config.autodeployment
end
