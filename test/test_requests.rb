require_relative 'test_helper'

class TestRequests < MiniTest::Test
  def test_user_agent
    sinew.dsl.get('http://httpbingo.org/get', a: 1, b: 2)
    assert_match(/sinew/, sinew.dsl.json[:headers][:'User-Agent'].to_s)
  end

  def test_basic_methods
    sinew.dsl.get('http://httpbingo.org/get', a: 1, b: 2)
    assert_equal(200, sinew.dsl.code)
    assert_equal({ a: ['1'], b: ['2'] }, sinew.dsl.json[:args])

    sinew.dsl.post('http://httpbingo.org/post', a: 1, b: 2)
    assert_equal({ a: ['1'], b: ['2'] }, sinew.dsl.json[:form])

    sinew.dsl.post_json('http://httpbingo.org/post', a: 1, b: 2)
    assert_equal({ a: 1, b: 2 }, sinew.dsl.json[:json])
  end

  def test_custom_headers
    sinew.dsl.http('get', 'http://httpbingo.org/get', headers: { "User-Agent": '007' })
    assert_match(/007/, sinew.dsl.json[:headers][:'User-Agent'].to_s)
  end

  def test_redirects
    # absolute redirect
    sinew.dsl.get('http://httpbingo.org/redirect/2')
    assert_equal 'http://httpbingo.org/get', sinew.dsl.url

    # and relative redirect
    sinew.dsl.get('http://httpbingo.org/relative-redirect/2')
    assert_equal 'http://httpbingo.org/get', sinew.dsl.url
  end

  def test_errors
    skip if test_network?

    # 500
    assert_output(/failed with 500/) do
      sinew.dsl.get('http://httpbingo.org/status/500')
      assert_equal 500, sinew.dsl.code
      assert_equal '500', sinew.dsl.raw
    end

    # timeout
    assert_output(/failed with 999/) do
      sinew.dsl.get('http://httpbingo.org/delay/1')
      assert_equal 999, sinew.dsl.code
    end

    # uncommon errors
    errors = [
      Errno::ECONNREFUSED,
      OpenSSL::SSL::SSLError.new,
      SocketError.new,
    ]
    errors.each_with_index do |error, index|
      stub_request(:get, %r{http://[^/]+/error#{index}}).to_return { raise error }
      assert_output(/failed with 999/) do
        sinew.dsl.get("http://httpbingo.org/error#{index}")
        assert_equal 999, sinew.dsl.code
      end
    end
  end

  def test_retry_timeout
    skip if test_network?

    errors = 2
    stub_request(:get, %r{http://[^/]+/error}).to_return do
      if errors > 0
        errors -= 1
        raise Timeout::Error
      end
      { body: 'done', status: 200 }
    end
    sinew.dsl.get('http://httpbingo.org/error')
    assert_equal 0, errors
    assert_equal 'done', sinew.dsl.raw
  end

  def test_retry500
    skip if test_network?

    errors = 2
    stub_request(:get, %r{http://[^/]+/error}).to_return do
      if errors > 0
        errors -= 1
        return { status: 500 }
      end
      { body: 'done', status: 200 }
    end
    sinew.dsl.get('http://httpbingo.org/error')
    assert_equal 0, errors
    assert_equal 'done', sinew.dsl.raw
  end

  def test_urls
    # simple
    req = Sinews::Request.new('get', 'https://host')
    assert_equal 'https://host', req.uri.to_s

    # with query
    req = Sinews::Request.new('get', 'https://host', query: { a: 1 })
    assert_equal 'https://host?a=1', req.uri.to_s

    # entity decoding
    req = Sinews::Request.new('get', 'https://host?a=&lt;5')
    assert_equal 'https://host?a=%3C5', req.uri.to_s

    # sloppy urls
    req = Sinews::Request.new('get', 'https://host?a=b c&d=f\'g')
    assert_equal 'https://host?a=b%20c&d=f%27g', req.uri.to_s
  end
end
