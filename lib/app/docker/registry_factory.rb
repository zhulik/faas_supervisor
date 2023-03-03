# frozen_string_literal: true

module App::Docker::RegistryFactory
  REGISTRIES = {
    "ghcr.io" => App::Docker::Registries::Ghcr.new,
    "docker.io" => App::Docker::Registries::Docker.new
  }.freeze

  def self.build(name)
    REGISTRIES[name].tap do |reg|
      raise ArgumentError, "registry #{name} is not supported" if reg.nil?
    end
  end
end
