# sinew
require 'sinew/args'
require 'sinew/base'
require 'sinew/csv'
require 'sinew/main'
require 'sinew/nokogiri_ext'
require 'sinew/response'
require 'sinew/version'

# custom faraday middleware
require 'sinew/middleware/log_formatter'

module Sinew
  # flow control for --limit
  class LimitError < StandardError; end

  # shortcut for Sinew::Base.new
  class << self
    def new(**args)
      Sinew::Base.new(**args)
    end
  end
end
