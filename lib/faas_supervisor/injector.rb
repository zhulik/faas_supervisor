# frozen_string_literal: true

module FaasSupervisor::Injector
  def inject(name)
    define_method(name) do
      FaasSupervisor::Application.instance.container[name]
    end
    private name
  end
end
