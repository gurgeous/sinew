require 'stringio'
require 'zlib'

#
# An HTTP response.
#

module Sinew
  class Response
    attr_accessor :request, :uri, :body, :code, :headers

    #
    # factory methods
    #

    def self.from_network(request, fday_response)
      Response.new.tap do
        _1.request = request
        _1.uri = fday_response.env.url
        _1.code = fday_response.status
        _1.headers = fday_response.headers.to_h
        _1.body = process_body(fday_response)
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
