# frozen_string_literal: true

module FaasSupervisor::Logger
  [:debug, :info, :warn, :error, :fatal].each do |name|
    define_method(name) do |msg = nil, &block|
      Console.logger.public_send(name, self, msg, &block)
    end

    define_method("#{name}_measure") do |lambda, &block|
      Async::Clock.measure { block.call }
                  .tap { |elapsed| public_send(name) { lambda.call(elapsed) } }
    end
  end
end
