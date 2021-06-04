require 'faraday'
require 'faraday-encoding'
require 'faraday/logging/formatter'
require 'httpdisk'
require 'sinews/connection/log_formatter'
require 'sinews/connection/rate_limit'

module Sinews
  module Connection
    def self.create(options:, runtime_options:)
      connection_options = {}
      connection_options[:ssl] = { verify: false } if runtime_options.insecure

      Faraday.new(nil, connection_options) do
        _1.use RateLimit, rate_limit: runtime_options.rate_limit

        # auto-encode form bodies
        _1.request :url_encoded

        # Before httpdisk so each redirect segment is cached
        # Keep track of redirect status for logger
        _1.response :follow_redirects, callback: ->(_old_env, new_env) { new_env[:redirect] = true }

        # set Ruby string encoding based on Content-Type (should be above httpdisk)
        _1.response :encoding

        # disk caching
        httpdisk_options = {
          dir: options[:dir],
          force: options[:force],
          force_errors: options[:force_errors],
        }.merge(runtime_options.httpdisk_options)

        _1.use :httpdisk, httpdisk_options

        # After httpdisk so that only non-cached requests are logged.
        # Before retry so that we don't log each retry attempt.
        _1.response :logger, nil, formatter: LogFormatter if !options[:quiet]

        # After httpdisk so transient failures are not cached
        retry_options = {
          interval: runtime_options.rate_limit,
          max: runtime_options.retries,
          methods: %w[delete get head options patch post put trace],
          retry_statuses: (500..600).to_a,
          retry_if: ->(_env, _err) { true },
        }
        _1.request :retry, retry_options
      end
    end
  end
end
