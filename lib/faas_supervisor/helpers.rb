# frozen_string_literal: true

module FaasSupervisor::Helpers
  include FaasSupervisor
  include FaasSupervisor::Logger

  T = FaasSupervisor::Types

  def self.included(base)
    base.extend(Dry::Initializer)
    base.extend(FaasSupervisor::Injector)

    base.include(Memery)
  end
end
