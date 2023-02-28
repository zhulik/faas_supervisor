# frozen_string_literal: true

class App::Struct < Dry::Struct
  include App
  include Memery

  T = App::Types
end
