require 'scripto'
require 'sinews/connection'

#
# Main sinew entry point.
#

module Sinews
  class Main < Scripto::Main
    attr_reader :runtime_options

    def initialize(options)
      super(options)

      # init
      @runtime_options = RuntimeOptions.new
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
    # http requests
    #

    def http(method, url, options = {})
      request = Request.new(method, url, request_options(options))
      response = request.perform(connection)

      # always log error messages
      if response.error?
        puts "xxx http request failed with #{response.code}"
      end

      response
    end

    def connection
      @connection ||= Connection.create(options: options, runtime_options: runtime_options)
    end
    protected :connection

    #
    # output
    #

    def output
      @output ||= Output.new(self)
    end

    #
    # helpers
    #

    def request_options(options)
      options.dup.tap do |req|
        req[:headers] = {}.tap do |h|
          [runtime_options.headers, options[:headers]].each do
            h.merge!(_1) if _1
          end
        end
        req[:proxy] = random_proxy
      end
    end
    protected :request_options

    PROXY_RE = /\A#{URI::PATTERN::HOST}(:\d+)?\Z/.freeze

    def random_proxy
      return if !options[:proxy]

      proxy = options[:proxy].split(',').sample
      if proxy !~ PROXY_RE
        raise ArgumentError, "invalid proxy #{proxy.inspect}, should be host[:port]"
      end

      "http://#{proxy}"
    end
    protected :random_proxy

    def footer
      output.report
      finished = output.count > 0 ? "Finished #{output.filename}" : 'Finished'
      banner("#{finished} in #{dsl.elapsed.to_i}s.")
    end
    protected :footer
  end
end
