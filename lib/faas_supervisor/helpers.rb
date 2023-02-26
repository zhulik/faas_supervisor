# frozen_string_literal: true

module FaasSupervisor::Helpers
  include FaasSupervisor
  include FaasSupervisor::Logger

  T = Dry.Types

  def self.included(base)
    base.extend(Dry::Initializer)
    base.extend(FaasSupervisor::Injector)

    base.include(Memery)
  end
end
