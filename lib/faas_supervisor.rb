# frozen_string_literal: true

require_relative "faas_supervisor/version"

require "zeitwerk"

require "memery"
require "faraday"

require "dry-initializer"
require "dry/struct"

loader = Zeitwerk::Loader.for_gem
loader.setup

class FaasSupervisor::Error < StandardError
  # Your code goes here...
end

loader.eager_load
