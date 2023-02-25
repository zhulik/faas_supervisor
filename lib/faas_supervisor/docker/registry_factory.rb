# frozen_string_literal: true

module FaasSupervisor::Docker::RegistryFactory
  include FaasSupervisor::Docker

  REGISTRIES = {
    "ghcr.io" => Registries::Ghcr.new
  }.freeze

  def self.build(name)
    REGISTRIES[name].tap do |reg|
      raise ArgumentError, "registry #{name} is not supported" if reg.nil?
    end
  end
end
