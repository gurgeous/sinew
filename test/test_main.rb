# encoding: UTF-8

require "helper"

module Sinew
  class TestMain < TestCase
    RECIPE = "#{TMP}/test.sinew"
    CSV    = "#{TMP}/test.csv"    

    def setup
      # create TMP dir
      FileUtils.rm_rf(TMP) if File.exists?(TMP)
      FileUtils.mkdir_p(TMP)
    end

    def run_recipe(recipe)
      File.write(RECIPE, recipe)
      Util.stub(:run, mock_curl_200) do
        Sinew::Main.new(cache: TMP, file: RECIPE, quiet: true)
      end
    end

    def test_noko
      run_recipe <<'EOF'
get "http://www.example.com"
csv_header(:class, :text)
noko.css("#main span").each do |span|
  csv_emit(class: span[:class], text: span.text)
end
EOF
      assert_equal("class,text\nclass1,text1\nclass2,text2\n", File.read(CSV))
    end

    def test_raw
      # test javascript, which is only crawlable with raw
      run_recipe <<'EOF'
get "http://www.example.com"
raw.scan(/alert\("([^"]+)/) do
  csv_emit(alert: $1)
end
EOF
      assert_equal("alert\nalert 1\nalert 2\n", File.read(CSV))
    end

    def test_html
      # note the cleaned up whitespace
      run_recipe <<'EOF'
get "http://www.example.com"
csv_header(:class, :text)
html.scan(/<span class="(\w+)">(\w+)/) do
  csv_emit(class: $1, text: $2)
end
EOF
      assert_equal("class,text\nclass1,text1\nclass2,text2\n", File.read(CSV))
    end

    def test_clean
      # note the removed attributes from span
      run_recipe <<'EOF'
get "http://www.example.com"
clean.scan(/<span>(text\d)/) do
  csv_emit(text: $1)
end
EOF
      assert_equal("text\ntext1\ntext2\n", File.read(CSV))      
    end

    def test_normalize
      s = Sinew::Main.new(test: true)

      #
      # non-strings
      #
      
      noko = Nokogiri::HTML(HTML).css("#main")      
      # node => text
      assert_equal("text", s.send(:_normalize, noko.css("#element")))
      # nodes => text joined with space
      assert_equal("text1 text2", s.send(:_normalize, noko.css(".e")))
      # array => text joined with pipe
      assert_equal("1|2", s.send(:_normalize, [1,2]))

      #
      # string cleanups
      #
      
      # untag
      assert_equal("gub", s.send(:_normalize, "<tag>gub</tag>"))
      # convert_accented_entities
      assert_equal("a", s.send(:_normalize, "&aacute;"))
      # unent
      assert_equal("<>", s.send(:_normalize, "&lt;&gt;"))
      # to_ascii
      assert_equal("cafe", s.send(:_normalize, "caf\xc3\xa9"))
      # squish
      assert_equal("hello world", s.send(:_normalize, "\nhello \t \rworld"))
    end
  end
end


