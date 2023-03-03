# frozen_string_literal: true

# TODO: extract a separate class for working image ids
class App::PodImage < Dry::Struct
  include App

  attribute :target, T::Constructor(Docker::ImageReference)
  attribute :deployed, T::Constructor(Docker::ImageReference)

  def registry = target.registry
  def owner = target.owner
  def name = target.name

  def tag = target.tag
  def full_name = target.full_name
  def digest = deployed.digest
end
