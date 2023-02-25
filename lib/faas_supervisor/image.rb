# frozen_string_literal: true

class FaasSupervisor::Image < Dry::Struct
  include Memery

  T = Dry.Types

  attribute :image, T::String
  attribute :image_id, T::String

  memoize def registry = image.split("/").first
  memoize def tag = image.split(":").last

  memoize def digest = image_id.split(":").last
end
