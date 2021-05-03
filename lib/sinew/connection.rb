require 'faraday'
require 'faraday-encoding'
require 'faraday/logging/formatter'
require 'httpdisk'
require 'sinew/connection/log_formatter'
require 'sinew/connection/rate_limit'

module Sinew
  module Connection
    def self.create(options:, runtime_options:)
      Faraday.new(nil) do
        _1.use RateLimit, rate_limit: runtime_options.rate_limit

        # BEFORE httpdisk so each redirect segment is cached
        # Keep track of redirect status for logger
        _1.response :follow_redirects, callback: ->(_old_env, new_env) { new_env[:redirect] = true }

        # set Ruby string encoding based on Content-Type (should be above httpdisk)
        _1.response :encoding

        # disk caching
        _1.use :httpdisk, dir: options[:cache]

        # AFTER httpdisk so transient failures are not cached
        retry_options = {
          interval: runtime_options.rate_limit,
          max: runtime_options.retries,
          methods: %w[delete get head options patch post put trace],
          retry_statuses: (500..600).to_a,
          retry_if: ->(_env, _err) { true },
        }
        _1.request :retry, retry_options

        # AFTER httpdisk so that only non-cached requests are logged
        _1.response :logger, nil, formatter: LogFormatter if !options[:quiet]
      end
    end
  end
end
