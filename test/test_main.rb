require_relative 'test_helper'

require 'base64'
require 'mocha'

class TestMain < MiniTest::Test
  def setup
    super

    # true network requests call sleep for timeouts, which interferes with our
    # instrumentation of Kernel#sleep
    skip if test_network?
  end

  def test_rate_limit
    # don't sleep, but expect it to get called
    Sinew::Connection::RateLimit.any_instance.expects(:sleep)

    sinew.runtime_options.rate_limit = 1
    sinew.dsl.get('http://httpbingo.org/html')
    sinew.dsl.get('http://httpbingo.org/get')
  end

  def test_gunzip
    body = Base64.decode64('H4sICBRI61oAA2d1Yi50eHQASy9N4gIAJlqRYgQAAAA=')
    body = Sinew::Response.process_body(OpenStruct.new(body: body))
    assert_equal 'gub', body.strip
  end
end
