# frozen_string_literal: true

# TODO: extract a separate class for working image ids
class App::Image < App::Struct
  attribute :image, T::Strict::String
  attribute :image_id, T::Strict::String

  def registry = tokens.first
  def owner = tokens[1]
  def name = tokens[2]

  memoize def tag = image.split(":").last
  memoize def full_name = "#{owner}/#{name}"
  memoize def digest = image_id.split("@").last

  private

  memoize def tokens = image.split(":").first.split("/")
end
