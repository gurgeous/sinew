#
# Runtime options that sinew files can modify.
#

module Sinew
  class RuntimeOptions
    attr_accessor :retries
    attr_accessor :rate_limit
    attr_accessor :headers
    attr_accessor :httparty_options
    attr_accessor :before_generate_cache_key

    def initialize
      self.retries = 3
      self.rate_limit = 1
      self.headers = {
        'User-Agent' => "sinew/#{VERSION}",
      }
      self.httparty_options = {}
      self.before_generate_cache_key = ->(i) { i }

      # for testing
      if ENV['SINEW_TEST']
        self.rate_limit = 0
      end
    end
  end
end
