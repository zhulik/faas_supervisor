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

module App
  class Error < StandardError; end

  def self.included(base)
    base.include(Async::App::Component)
    base.include(Memery)
  end
end

loader.eager_load
