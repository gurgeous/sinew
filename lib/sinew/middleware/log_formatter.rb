module Sinew
  module Middleware
    class LogFormatter < Faraday::Logging::Formatter
      def request(env)
        info('req') do
          # Only log the initial request, not the redirects
          return if env[:redirect]

          msg = apply_filters(env.url.to_s)
          msg = "#{msg} (#{env.method})" if env.method != :get
          msg = "#{msg} => #{env.request.proxy.uri}" if env.request.proxy

          msg
        end
      end

      def response(env)
        # silent
      end
    end
  end
end
