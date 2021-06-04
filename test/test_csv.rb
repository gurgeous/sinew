require 'test_helper'

class TestCsv < MiniTest::Test
  def test_path
    [
      %w[gub.rb gub.csv],
      %w[/zub/gub.rb /zub/gub.csv],
      %w[../zub/gub.rb ../zub/gub.csv],
    ].each do
      assert_equal _2, Sinew::CSV.new(_1).path
    end
  end

  def test_emit
    csv = Sinew::CSV.new("#{@tmpdir}/test.rb")
    csv.start(%i[a b])
    print = csv.emit(a: 1)
    assert_equal({ a: '1' }, print)
    assert_equal 1, csv.count
    assert_equal({ a: 1, b: 0 }, csv.tally)
    assert_equal("a,b\n1,\n", IO.read(csv.path))
  end

  def test_normalize
    csv = Sinew::CSV.new(nil)
    noko = Nokogiri::HTML(IO.read("#{__dir__}/test.html"))

    assert_nil csv.normalize(nil)
    assert_nil csv.normalize('')

    [
      #
      # simple types
      #

      %w[text text],
      [123, '123'],
      [[1, 2], '1|2'],

      #
      # nokogiri
      #

      # node => text
      [noko.css('#element'), 'text'],
      # nodes => text joined with space
      [noko.css('.e'), 'text1 text2'],

      #
      # string cleanups
      #

      # strip_html_tags
      ['<tag>gub</tag>', 'gub'],
      # strip_html_tags and replace with spaces
      ['<tag>hello<br>world</tag>', 'hello world'],
      # convert_smart_punctuation
      ["\302\223gub\302\224", '"gub"'],
      # convert_accented_html_entities
      ['&aacute;', 'a'],
      # convert_miscellaneous_html_entities
      ['&lt;&amp;&gt;', '<&>'],
      # to_ascii
      %w[café cafe],
      # squish
      ["\nhello \t \rworld", 'hello world'],
    ].each do
      assert_equal(_2, csv.normalize(_1))
    end
  end
end
