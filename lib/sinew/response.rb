#
# An HTTP response. Mostly a wrapper around HTTParty.
#

module Sinew
  class Response
    attr_accessor :request, :uri, :body, :code, :headers

    #
    # factory methods
    #

    def self.from_network(request, party_response)
      Response.new.tap do |response|
        response.request = request
        response.uri = party_response.request.last_uri
        response.code = party_response.code
        response.headers = party_response.headers.to_h

        # force to utf-8 as best we can
        body = party_response.body
        if body.encoding != Encoding::UTF_8
          body = body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
        end
        response.body = body
      end
    end

    def self.from_cache(request, body, head)
      Response.new.tap do |response|
        response.request = request
        response.body = body

        # defaults
        response.uri = request.uri
        response.code = 200
        response.headers = {}

        # overwrite with cached response headers
        if head
          if head !~ /^{/
            return from_legacy_head(response, head)
          end
          head = JSON.parse(head, symbolize_names: true)
          response.uri = URI.parse(head[:uri])
          response.code = head[:code]
          response.headers = head[:headers]
        end
      end
    end

    def self.from_timeout(request)
      Response.new.tap do |response|
        response.request = request
        response.uri = request.uri
        response.body = 'timeout'
        response.code = 999
        response.headers = {}
      end
    end

    def self.from_legacy_head(response, head)
      response.tap do |response|
        case head
        when /\ACURLER_ERROR/
          # error
          response.code = 999
        when /\AHTTP/
          # redirect
          location = head.scan(/Location: ([^\r\n]+)/).flatten.last
          response.uri += location
        else
          $stderr.puts "unknown cached /head for #{response.uri}"
        end
      end
    end

    #
    # accessors
    #

    def error?
      code >= 400
    end

    def error_500?
      code / 100 >= 5
    end

    def redirected?
      request.uri != uri
    end

    def head_as_json
      {
        uri: uri,
        code: code,
        headers: headers,
      }
    end
  end
end
