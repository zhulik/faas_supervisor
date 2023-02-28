# frozen_string_literal: true

module App::Helpers
  include App
  include App::Logger

  T = App::Types

  def self.included(base)
    base.extend(Dry::Initializer)
    base.extend(App::Injector)

    base.include(Memery)
  end
end
