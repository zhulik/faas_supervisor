# frozen_string_literal: true

class App::IntervalParser
  UNITS = {
    "s" => 1,
    "m" => 60,
    "h" => 60 * 60,
    "d" => 60 * 60 * 24
  }.freeze

  class << self
    def parse(str) = validate(str).then { _1 * UNITS[_2] }

    private

    def validate(str)
      raise ArgumentError, "argument must be a string" unless str.is_a?(String)

      *num, unit = str.chars
      raise ArgumentError, "unknown unit #{unit}" unless UNITS.key?(unit)

      begin
        interval = Float(num.join)
      rescue ArgumentError
        raise ArgumentError, "cannot parse #{str}"
      end
      raise ArgumentError, "interval cannot be 0" if interval.zero?

      [interval, unit]
    end
  end
end
