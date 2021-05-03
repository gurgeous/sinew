require 'scripto'
require 'sinew/connection'

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
    # http requests
    #

    def http(method, url, options = {})
      request = Request.new(self, method, url, options)
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

    def footer
      output.report
      finished = output.count > 0 ? "Finished #{output.filename}" : 'Finished'
      banner("#{finished} in #{dsl.elapsed.to_i}s.")
    end
    protected :footer
  end
end
