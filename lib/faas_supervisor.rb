# frozen_string_literal: true

require "singleton"

require "zeitwerk"

require "async"
require "async/barrier"
require "async/http"
require "async/tools"

require "memery"

require "faraday"

require "dry-initializer"
require "dry/events"
require "dry/container"
require "dry/struct"

require "prometheus/api_client"

require "get_process_mem"

require "zilla"

Dry::Struct.load_extensions(:pretty_print)

loader = Zeitwerk::Loader.for_gem
loader.setup

module FaasSupervisor # rubocop:disable Style/ClassAndModuleChildren
  class Error < StandardError; end
end

loader.eager_load
