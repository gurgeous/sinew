# manually load dependencies here since this is loaded standalone by bin
require "httpdisk/slop_duration"
require "sinew/version"
require "slop"

#
# This is used to parse command line arguments with Slop. We don't set any
# defaults in here, relying instead on Sloptions in Sinew::Base. That way
# defaults are applied for both command line and embedded usage of Sinew::Base.
#

module Sinew
  module Args
    def self.slop(args)
      slop = Slop.parse(args) do |o|
        o.banner = "Usage: sinew [options] [recipe.sinew]"
        o.integer "-l", "--limit", "quit after emitting this many rows"
        o.string "--proxy", "use host[:port] as HTTP proxy (can be a comma-delimited list)"
        o.integer "--timeout", "maximum time allowed for the transfer"
        o.bool "-s", "--silent", "suppress some output"
        o.bool "-v", "--verbose", "dump emitted rows while running"

        o.separator "From httpdisk:"
        o.string "--dir", "set custom cache directory"
        # note: uses slop_duration from HTTPDisk
        o.duration "--expires", "when to expire cached requests (ex: 1h, 2d, 3w)"
        o.bool "--force", "don't read anything from cache (but still write)"
        o.bool "--force-errors", "don't read errors from cache (but still write)"

        # generic
        o.boolean "--version", "show version" do
          puts "sinew #{Sinew::VERSION}"
          exit
        end
        o.on("--help", "show this help") do
          puts o
          exit
        end
      end

      # recipe argument
      recipe = slop.args.first
      raise Slop::Error, "" if args.empty?
      raise Slop::Error, "no RECIPE specified" if !recipe
      raise Slop::Error, "more than one RECIPE specified" if slop.args.length > 1
      raise Slop::Error, "#{recipe} not found" if !File.exist?(recipe)

      slop.to_h.tap do
        _1[:recipe] = recipe
      end
    end
  end
end
