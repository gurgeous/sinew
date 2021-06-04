# manually load dependencies here since this is loaded standalone by bin
require 'sinews/version'
require 'slop'

module Sinews
  module Args
    def self.slop(args)
      slop = Slop.parse(args) do |o|
        o.banner = 'Usage: sinew [options] [recipe]'
        o.bool '-v', '--verbose', 'dump emitted rows while running'
        o.bool '-s', '--silent', 'suppress some output'
        o.integer '-l', '--limit', 'quit after emitting this many rows'
        o.string '--dir', 'set custom cache directory', default: "#{ENV['HOME']}/.sinew"
        o.bool '--force', "don't read anything from cache (but still write)"
        o.bool '--force-errors', "don't read errors from cache (but still write)"
        o.string '--proxy', 'use host[:port] as HTTP proxy (can be a comma-delimited list)'
        o.boolean '--version', 'show version' do
          puts "sinew #{Sinews::VERSION}"
          exit
        end
        o.on('--help', 'show this help') do
          puts o
          exit
        end
      end

      # look for recipe argument
      raise Slop::Error, '' if args.empty?
      raise Slop::Error, 'more than one RECIPE specified' if slop.args.length > 1

      recipe = slop.args.first
      raise Slop::Error, 'no RECIPE specified' if !recipe
      raise Slop::Error, "#{recipe} not found" if !File.exist?(recipe)

      slop.to_h.tap do
        _1[:recipe] = recipe
      end
    end
  end
end
