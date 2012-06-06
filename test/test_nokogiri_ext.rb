require "helper"

module Sinew
  class TestNokogiriExt < TestCase
    def setup
      @noko = Nokogiri::HTML(HTML).css("#nokogiri_ext")
    end
    
    def test_inner_text
      assert_equal("hello world", @noko.css("li").inner_text)
      assert_equal("<li>hello</li> <li>world</li>", @noko.css("ul").inner_html.squish)
    end

    def test_just_me
      assert_equal("a", @noko.css("div").text_just_me.squish)
      assert_equal("b b", @noko.css("p").text_just_me.squish)    
    end
  end
end
