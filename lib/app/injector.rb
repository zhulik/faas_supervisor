# frozen_string_literal: true

module App::Injector
  def inject(name)
    define_method(name) do
      App::Application.instance.container[name]
    end
    private name
  end
end
