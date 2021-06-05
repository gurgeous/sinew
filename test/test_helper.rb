require 'English'
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/minitest'
require 'sinew'
require 'webmock/minitest'

# a hint to sinew, so that it'll do things like set rate limit to zero
ENV['SINEW_TEST'] = '1'

module MiniTest
  class Test
    def setup
      @tmpdir = Dir.mktmpdir('sinew')
      @httpbingo_stub = stub_request(:any, /httpbingo/).to_return { httpbingo(_1) }
      # like httpbingo, for testing
      # stub_request(:get, %r{http://[^/]+/html}).to_return(method(:respond_html))
      # stub_request(:get, %r{http://[^/]+/get\b}).to_return(method(:respond_echo))
      # stub_request(:post, %r{http://[^/]+/post\b}).to_return(method(:respond_echo))
      # stub_request(:get, %r{http://[^/]+/status/\d+}).to_return(method(:respond_status))
      # stub_request(:get, %r{http://[^/]+/(relative-)?redirect/\d+}).to_return(method(:respond_redirect))
      # stub_request(:get, %r{http://[^/]+/delay/\d+}).to_timeout
      # stub_request(:get, %r{http://[^/]+/xml}).to_return(method(:respond_xml))
    end

    def teardown
      FileUtils.rm_rf(@tmpdir)
      WebMock.reset!
    end

    protected

    # write a tmp recipe with code, return the path
    def recipe(code)
      code = <<~EOF
        class Recipe < Sinew::Base
          def run
            #{code}
          end
        end
      EOF

      File.join(@tmpdir, 'recipe.rb').tap do
        IO.write(_1, code)
      end
    end

    #
    # a really bad httpbingo.org for webmock
    #

    def httpbingo(request)
      # support for /redirect/:n
      case request.uri.path
      when %r{/redirect/(\d+)}
        n = Regexp.last_match(1).to_i
        location = n > 1 ? "/redirect/#{n - 1}" : '/get'
        return { status: 302, headers: { Location: location } }

      when '/html'
        return { body: <<~EOF }
          <body>
            <h1>Herman Melville - Moby-Dick</h1>
          </body>
        EOF

      when '/xml'
        return { body: <<~EOF }
          <!--   A SAMPLE set of slides   -->
          <slideshow>
            <slide type="all">
              <title>Wake up to WonderWidgets!</title>
            </slide>
            <slide type="all">
              <title>Overview</title>
            </slide>
          </slideshow>
        EOF
      end

      # otherwise just echo
      body = {}.tap do |h|
        if q = request.uri.query
          h[:args] = CGI.parse(q).map { [_1, _2.join(',')] }.to_h
        end
        h[:body] = request.body
        h[:headers] = request.headers
        h[:method] = request.method
        h[:rand] = rand # helpful for testing caching
      end.compact

      { body: JSON.pretty_generate(body) }
    end

    # load test.html
    def test_html
      IO.read(File.join(__dir__, 'test.html'))
    end
  end
end
