require 'slop'

module Slop
  # Custom duration type for Slop, used for --expires. Raises aggressively
  # because this is a tricky and lightly documented option.
  class DurationOption < Option
    UNITS = {
      s: 1,
      m: 60,
      h: 60 * 60,
      d: 24 * 60 * 60,
      w: 7 * 24 * 60 * 60,
      y: 365 * 7 * 24 * 60 * 60,
    }.freeze

    def call(value)
      m = value.match(/^(\d+)([smhdwy])?$/)
      raise Slop::Error, "invalid --expires #{value.inspect}" if !m

      num, unit = m[1].to_i, (m[2] || 's').to_sym
      num * UNITS[unit]
    end
  end
end
