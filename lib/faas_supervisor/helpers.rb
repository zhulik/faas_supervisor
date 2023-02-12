# frozen_string_literal: true

module FaasSupervisor::Helpers
  T = Dry.Types

  def self.included(base)
    base.extend(Dry::Initializer)
    base.include(FaasSupervisor::Logger)
    base.include(Memery)
  end
end
