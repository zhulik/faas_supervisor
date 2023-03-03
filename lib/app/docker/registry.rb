# frozen_string_literal: true

module App::Docker::Registry
  class << self
    def supported?(reference) = App::Docker::RegistryFactory.supported?(reference.registry)

    def published_digest(reference) = App::Docker::RegistryFactory.build(reference).published_digest(reference)
  end
end
