# frozen_string_literal: true

class FaasSupervisor::Struct < Dry::Struct
  include FaasSupervisor
  include Memery

  T = FaasSupervisor::Types
end
