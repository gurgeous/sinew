require_relative "test_helper"

class TestNokogiriExt < Minitest::Test
  def test_inner_text
    noko = Nokogiri::HTML(test_html).css("#nokogiri_ext")

    assert_equal("hello world", noko.css("li").inner_text)
    assert_equal("<li>hello</li> <li>world</li>", noko.css("ul").inner_html.strip.gsub(/\s+/, " "))
  end
end
