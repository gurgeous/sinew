require 'scripto'

#
# Main sinew entry point.
#

module Sinew
  class Main < Scripto::Main
    attr_reader :runtime_options, :request_tm, :request_count

    def initialize(options)
      super(options)

      # init
      @runtime_options = RuntimeOptions.new
      @request_tm = Time.at(0)
      @request_count = 0
    end

    def run
      dsl.run
      footer if !quiet?
    end

    def quiet?
      options[:quiet]
    end

    def dsl
      @dsl ||= DSL.new(self)
    end

    #
    # http requests and caching
    #

    def cache
      @cache ||= Cache.new(self)
    end

    def http(method, url, options = {})
      request = Request.new(self, method, url, options)

      # try to get from cache
      response = cache.get(request)

      # perform if necessary
      if !response
        response = perform(request)
        cache.set(response)
      end

      # always log error messages
      if response.error?
        puts "xxx http request failed with #{response.code}"
      end

      response
    end

    def perform(request)
      before_perform_request(request)

      response = nil

      tries = runtime_options.retries + 1
      while tries > 0
        tries -= 1
        begin
          @request_count += 1
          response = request.perform
        rescue Timeout::Error
          response = Response.from_timeout(request)
        end
        break if !response.error_500?
      end

      response
    end
    protected :perform

    #
    # output
    #

    def output
      @output ||= Output.new(self)
    end

    #
    # helpers
    #

    def before_perform_request(request)
      # log
      if !quiet?
        msg = if request.method != 'get'
          "req #{request.uri} (#{request.method})"
        else
          "req #{request.uri}"
        end
        $stderr.puts msg
      end

      # rate limit
      sleep = (request_tm + runtime_options.rate_limit) - Time.now
      sleep(sleep) if sleep > 0
      @request_tm = Time.now
    end
    protected :before_perform_request

    def footer
      output.report
      finished = output.count > 0 ? "Finished #{output.filename}" : 'Finished'
      banner("#{finished} in #{dsl.elapsed.to_i}s.")
    end
    protected :footer
  end
end
