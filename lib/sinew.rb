# sinew
require 'sinew/args'
require 'sinew/base'
require 'sinew/csv'
require 'sinew/main'
require 'sinew/nokogiri_ext'
require 'sinew/response'
require 'sinew/version'

# for slop
require 'sinew/slop_duration'

# custom faraday middleware
require 'sinew/middleware/log_formatter'

module Sinew
  # flow control for --limit
  class LimitError < StandardError; end
end
