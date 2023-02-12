# frozen_string_literal: true

require "zeitwerk"

require "async"
require "async/barrier"

require "memery"

require "faraday"
require "faraday_middleware"

require "dry-initializer"
require "dry/struct"

require "prometheus/api_client"

Dry::Struct.load_extensions(:pretty_print)

loader = Zeitwerk::Loader.for_gem
loader.setup

module FaasSupervisor # rubocop:disable Style/ClassAndModuleChildren
  class Error < StandardError; end
  # Your code goes here...
end

loader.eager_load
