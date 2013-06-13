require "helper"

module Sinew
  class TestTextUtil < TestCase
    def test_tidy
      tidy = TextUtil.html_tidy(HTML)
      # tags removed?
      assert(tidy !~ /script|meta/)
      # squished?
      assert(tidy !~ /  /)
      # comments removed?
      assert(tidy !~ /<!--/)      
    end

    def test_clean
      clean = TextUtil.html_clean(HTML)
      # attributes removed
      assert(clean !~ /will_be_removed/)
      # attributes preserved
      assert(clean =~ /will_be_preserved/)
    end

    def test_convert_accented_entities
      assert_equal 'a', TextUtil.convert_accented_entities("&aacute;")
      assert_equal 'c', TextUtil.convert_accented_entities("&ccedil;")
    end
  end
end
