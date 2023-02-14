# frozen_string_literal: true

module FaasSupervisor::Helpers
  T = Dry.Types

  module Injector
    def inject(name)
      define_method(name) do
        FaasSupervisor::Application[name]
      end
    end
  end

  def self.included(base)
    base.extend(Dry::Initializer)
    base.extend(Injector)

    base.include(FaasSupervisor)
    base.include(FaasSupervisor::Logger)
    base.include(Memery)
  end
end
