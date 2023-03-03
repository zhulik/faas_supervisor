# frozen_string_literal: true

module App::Docker::RegistryFactory
  REGISTRIES = {
    "ghcr.io" => App::Docker::Registries::Ghcr.new,
    "docker.io" => App::Docker::Registries::Docker.new
  }.freeze

  class << self
    def build(reference)
      REGISTRIES[reference.registry].tap do |reg|
        raise ArgumentError, "registry of #{reference} is not supported" if reg.nil?
      end
    end

    def supported?(name) = REGISTRIES.key?(name)
  end
end
