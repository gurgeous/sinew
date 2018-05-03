require_relative 'test_helper'

class TestLegacy < MiniTest::Test
  def setup
    super

    # These are legacy cache files, pulled from an older version of sinew. We
    # use them to test our legacy head parsing.
    src = 'legacy/eu.httpbin.org'
    dst = "#{TMP}/eu.httpbin.org"
    FileUtils.cp_r(File.expand_path(src, __dir__), dst)
  end

  def test_legacy
    assert_output(/failed with 999/) do
      sinew.dsl.get('http://eu.httpbin.org/status/500')
      assert_equal "\n", sinew.dsl.raw
    end

    sinew.dsl.get('http://eu.httpbin.org/redirect/3')
    assert_equal 'http://eu.httpbin.org/get', sinew.dsl.url
  end
end
