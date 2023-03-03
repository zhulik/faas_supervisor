# frozen_string_literal: true

module App::Helpers
  def self.included(base)
    base.include(App)
    base.include(Async::App::Component)
    base.include(Memery)
  end
end
