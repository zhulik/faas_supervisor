# frozen_string_literal: true

class FaasSupervisor::Image < Dry::Struct
  include Memery

  T = Dry.Types

  attribute :image, T::String
  attribute :image_id, T::String

  def registry = tokens.first
  def owner = tokens[1]
  def name = tokens[2]

  memoize def tag = image.split(":").last
  memoize def full_name = "#{owner}/#{name}"
  memoize def digest = image_id.split("@").last

  private

  memoize def tokens = image.split(":").first.split("/")
end
