module Sinews
  module Connection
    class RateLimit < Faraday::Middleware
      attr_reader :rate_limit

      def initialize(app, options = {})
        super(app)

        @last_request_tm = @current_request_tm = nil
        @rate_limit = options.fetch(:rate_limit, 1)
      end

      def on_request(_env)
        if @last_request_tm
          sleep = (@last_request_tm + rate_limit) - Time.now
          sleep(sleep) if sleep > 0
        end

        @current_request_tm = Time.now
      end

      def on_complete(env)
        # Only rate limit on uncached requests
        @last_request_tm = @current_request_tm unless env[:httpdisk]
        @current_request_tm = nil
      end
    end
  end
end
