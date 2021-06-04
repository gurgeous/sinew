require_relative 'sinew/args'
require_relative 'sinew/csv'
require_relative 'sinew/base'
require_relative 'sinew/main'
require_relative 'sinew/nokogiri_ext'
require_relative 'sinew/response'
require_relative 'sinew/version'

require_relative 'sinew/middleware/log_formatter'

# finalize package names
# dup url detection (output.rb)
# sloppy url cleanup (request.rb)
# auto inflate (response)
# --expires handling
# tests
# README

module Sinew
  # flow control for --limit
  class LimitError < StandardError; end
end
