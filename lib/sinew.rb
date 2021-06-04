require_relative 'sinews/args'
require_relative 'sinews/csv'
require_relative 'sinews/base'
require_relative 'sinews/main'
require_relative 'sinews/nokogiri_ext'
require_relative 'sinews/response'
require_relative 'sinews/version'

require_relative 'sinews/middleware/log_formatter'

# missing features off the top of my head
# rate limiter in gemspec
# dup url detection (output.rb)
# auto inflate?
# expires handling
# tests

# This makes it easier to write standalone sinews.
class Sinew < Sinews::Base
end

module Sinews
  # flow control for --limit
  class LimitError < StandardError; end
end
