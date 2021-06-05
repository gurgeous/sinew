require 'test_helper'

class TestResponse < MiniTest::Test
  def test_bodies
    assert_equal '<hey>you', response(' <hey>  you  ').html
    assert_equal({ a: 1 }, response('{"a":1}').json)
    assert_equal(1, response('{"a":1}').mash.a)
    assert_match(%r{<a>b</a>}, response('<a>b').noko.to_s)
    assert_match(%r{<a>b</a>}, response('<a>b</a>').xml.to_s)
  end

  protected

  def response(body)
    Sinew::Response.new(OpenStruct.new(body: body))
  end
end
