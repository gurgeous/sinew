require 'stringio'
require 'zlib'

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
        response.body = process_body(party_response)
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

    def self.from_error(request, error)
      Response.new.tap do |response|
        response.request = request
        response.uri = request.uri
        response.body = error.to_s
        response.code = 999
        response.headers = {}
      end
    end

    def self.from_legacy_head(response, head)
      response.tap do |r|
        case head
        when /\ACURLER_ERROR/
          # error
          r.code = 999
        when /\AHTTP/
          # redirect
          location = head.scan(/Location: ([^\r\n]+)/).flatten.last
          r.uri += location
        else
          $stderr.puts "unknown cached /head for #{r.uri}"
        end
      end
    end

    # helper for decoding bodies before parsing
    def self.process_body(response)
      body = response.body

      # inflate if necessary
      bits = body[0, 10].force_encoding('BINARY')
      if bits =~ /\A\x1f\x8b/n
        body = Zlib::GzipReader.new(StringIO.new(body)).read
      end

      # force to utf-8 if we think this could be text
      if body.encoding != Encoding::UTF_8
        if content_type = response.headers['content-type']
          if content_type =~ /\b(html|javascript|json|text|xml)\b/
            body = body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
          end
        end
      end

      body
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
