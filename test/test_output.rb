require_relative 'test_helper'

class TestOutput < MiniTest::Test
  def test_filenames
    sinew = Sinew::Main.new(recipe: 'gub.sinew')
    assert_equal 'gub.csv', sinew.output.filename
    sinew = Sinew::Main.new(recipe: 'gub')
    assert_equal 'gub.csv', sinew.output.filename
    sinew = Sinew::Main.new(recipe: '/somewhere/gub.sinew')
    assert_equal '/somewhere/gub.csv', sinew.output.filename
  end

  def test_normalization
    output = Sinew::Output.new(nil)

    #
    # simple types
    #

    assert_equal '', output.send(:normalize, nil)
    assert_equal '', output.send(:normalize, '')
    assert_equal 'text', output.send(:normalize, 'text')
    assert_equal '123', output.send(:normalize, 123)
    assert_equal('1|2', output.send(:normalize, [ 1, 2 ]))

    #
    # nokogiri
    #

    noko = Nokogiri::HTML(HTML)

    # node => text
    assert_equal('text', output.send(:normalize, noko.css('#element')))
    # nodes => text joined with space
    assert_equal('text1 text2', output.send(:normalize, noko.css('.e')))

    #
    # string cleanups
    #

    # strip_html_tags
    assert_equal('gub', output.send(:normalize, '<tag>gub</tag>'))
    # convert_smart_punctuation
    assert_equal('"gub"', output.send(:normalize, "\302\223gub\302\224"))
    # convert_accented_html_entities
    assert_equal('a', output.send(:normalize, '&aacute;'))
    # convert_miscellaneous_html_entities
    assert_equal('<>', output.send(:normalize, '&lt;&gt;'))
    # to_ascii
    assert_equal('cafe', output.send(:normalize, "caf\xc3\xa9"))
    # squish
    assert_equal('hello world', output.send(:normalize, "\nhello \t \rworld"))
  end
end
