require_relative 'test_helper'

class TestRequests < MiniTest::Test
  def test_get
    # network (or stub)
    sinew.dsl.get('http://httpbin.org/get')
    assert_equal 'UTF-8', sinew.dsl.raw.encoding.name

    # disk
    sinew.dsl.get('http://httpbin.org/get')
    assert_equal 'UTF-8', sinew.dsl.raw.encoding.name
  end

  def test_utf8
    skip if !test_network?

    # network
    sinew.dsl.get('http://httpbin.org/encoding/utf8')
    assert_equal 'UTF-8', sinew.dsl.raw.encoding.name
    assert_match(/∑/, sinew.dsl.raw)

    # disk
    sinew.dsl.get('http://httpbin.org/encoding/utf8')
    assert_equal 'UTF-8', sinew.dsl.raw.encoding.name
    assert_match(/∑/, sinew.dsl.raw)
  end

  def test_encode
    skip if !test_network?

    # network
    sinew.dsl.get('https://www.google.co.jp')
    assert_equal 'UTF-8', sinew.dsl.raw.encoding.name

    # disk
    sinew.dsl.get('https://www.google.co.jp')
    assert_equal 'UTF-8', sinew.dsl.raw.encoding.name
  end
end
