require_relative 'test_helper'

class TestCache < MiniTest::Test
  def test_get
    2.times do
      sinew.dsl.get('http://httpbingo.org/get', c: 3, d: 4)
    end
    if !test_network?
      assert_requested :get, 'http://httpbingo.org/get?c=3&d=4', times: 1
    end
    assert_equal({ c: [ '3' ], d: [ '4' ] }, sinew.dsl.json[:args])
  end

  def test_post
    2.times do
      sinew.dsl.post('http://httpbingo.org/post', c: 5, d: 6)
    end
    if !test_network?
      assert_requested :post, 'http://httpbingo.org/post', times: 1
    end
    assert_equal({ c: [ '5' ], d: [ '6' ] }, sinew.dsl.json[:form])
  end

  def test_redirect
    2.times do
      sinew.dsl.get('http://httpbingo.org/redirect/2')
    end
    if !test_network?
      assert_requested :get, 'http://httpbingo.org/redirect/2', times: 1
      assert_requested :get, 'http://httpbingo.org/redirect/1', times: 1
      assert_requested :get, 'http://httpbingo.org/get', times: 1
    end
    assert_equal 'http://httpbingo.org/get', sinew.dsl.url
  end

  def test_error
    # gotta set this or the retries mess up our request counts
    sinew.runtime_options.retries = 0
    assert_output(/failed with 500/) do
      2.times do
        sinew.dsl.get('http://httpbingo.org/status/500')
      end
    end
    if !test_network?
      assert_requested :get, 'http://httpbingo.org/status/500', times: 1
      assert_equal '500', sinew.dsl.raw
    end
  end

  def test_timeout
    return if test_network?

    # gotta set this or the retries mess up our request counts
    sinew.runtime_options.retries = 0
    assert_output(/failed with 999/) do
      2.times do
        sinew.dsl.get('http://httpbingo.org/delay/1')
      end
    end
    assert_requested :get, 'http://httpbingo.org/delay/1', times: 1
    assert_empty sinew.dsl.raw
  end

  def test_force
    sinew.options[:force] = true

    2.times do
      sinew.dsl.get('http://httpbingo.org/get', c: 3, d: 4)
    end
    if !test_network?
      assert_requested :get, 'http://httpbingo.org/get?c=3&d=4', times: 2
    end
  end

  def test_force_errors
    return if test_network?

    sinew.options[:force_errors] = true

    # gotta set this or the retries mess up our request counts
    sinew.runtime_options.retries = 0

    2.times do
      sinew.dsl.get('http://httpbingo.org/get', c: 3, d: 4)
    end

    assert_output(/failed with 999/) do
      2.times do
        sinew.dsl.get('http://httpbingo.org/delay/1')
      end
    end

    assert_requested :get, 'http://httpbingo.org/get?c=3&d=4', times: 1
    assert_requested :get, 'http://httpbingo.org/delay/1', times: 2
  end
end
