require 'minitest/autorun'
require 'minitest/pride'
require 'webmock/minitest' unless ENV['SINEW_TEST_NETWORK']

# a hint to sinew, so that it'll do things like set rate limit to zero
ENV['SINEW_TEST'] = '1'

# Normally the Rakefile takes care of this, but it's handy to have it here when
# running tests individually.
$LOAD_PATH.unshift("#{__dir__}/../lib")
require 'sinew'

class MiniTest::Test
  TMP = '/tmp/_test_sinew'.freeze
  RECIPE = "#{TMP}/test.sinew".freeze
  CSV = "#{TMP}/test.csv".freeze
  HTML = File.read("#{__dir__}/test.html")

  def setup
    super

    # prepare TMP
    FileUtils.rm_rf(TMP)
    FileUtils.mkdir_p(TMP)

    stub_network unless test_network?
  end

  def sinew
    @sinew ||= Sinew::Main.new(cache: TMP, quiet: true, recipe: RECIPE)
  end
  protected :sinew

  def run_recipe(recipe)
    File.write(RECIPE, recipe)
    sinew.run
  end
  protected :run_recipe

  def test_network?
    !!ENV['SINEW_TEST_NETWORK']
  end
  protected :test_network?

  # mock requests, patterned on httpbin
  def stub_network
    stub_request(:get, %r{http://[^/]+/html}).to_return(method(:respond_html))
    stub_request(:get, %r{http://[^/]+/get\b}).to_return(method(:respond_echo))
    stub_request(:post, %r{http://[^/]+/post\b}).to_return(method(:respond_echo))
    stub_request(:get, %r{http://[^/]+/status/\d+}).to_return(method(:respond_status))
    stub_request(:get, %r{http://[^/]+/(relative-)?redirect/\d+}).to_return(method(:respond_redirect))
    stub_request(:get, %r{http://[^/]+/delay/\d+}).to_timeout
  end
  protected :stub_network

  #
  # respond_xxx helpers
  #

  def respond_html(_request)
    # this html was carefully chosen to match httpbin.org/html
    html = <<~EOF
      <body>
        <h1>Herman Melville - Moby-Dick</h1>
      </body>
    EOF
    { body: html }
  end
  protected :respond_html

  def respond_echo(request)
    response = {}
    response[:headers] = request.headers

    # args
    response[:args] = if request.uri.query
      CGI.parse(request.uri.query).transform_values(&:first)
    else
      {}
    end

    # form
    if request.headers['Content-Type'] == 'application/x-www-form-urlencoded'
      response[:form] = CGI.parse(request.body).transform_values(&:first)
    end

    # json
    if request.headers['Content-Type'] == 'application/json'
      response[:json] = JSON.parse(request.body)
    end

    {
      headers: { 'Content-Type' => 'application/json' },
      body: response.to_json,
    }
  end
  protected :respond_echo

  def respond_status(request)
    status = request.uri.to_s.split('/').last.to_i
    { body: status.to_s, status: status }
  end
  protected :respond_status

  def respond_redirect(request)
    parts = request.uri.to_s.split('/')
    path, count = parts[-2], parts[-1].to_i
    url = count == 1 ? '/get' : "/#{path}/#{count - 1}"
    url = "http://example#{url}" if path =~ /absolute/
    { status: 302, headers: { 'Location' => url } }
  end
  protected :respond_redirect
end
