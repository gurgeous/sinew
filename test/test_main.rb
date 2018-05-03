require_relative 'test_helper'

class TestMain < MiniTest::Test
  def test_basic
    run_recipe <<~'EOF'
      get "http://httpbin.org/html"
      raw.scan(/<h1>([^<]+)/) do
        csv_emit(h1: $1)
      end
    EOF
    assert_equal("h1\nHerman Melville - Moby-Dick\n", IO.read(CSV))
  end

  def test_noko
    run_recipe <<~'EOF'
      get 'http://httpbin.org/html'
      noko.css("h1").each do |h1|
        csv_emit(h1: h1.text)
      end
    EOF
    assert_equal("h1\nHerman Melville - Moby-Dick\n", IO.read(CSV))
  end

  def test_xml
    run_recipe <<~'EOF'
      get 'http://httpbin.org/xml'
      noko.css("slide title").each do |title|
        csv_emit(title: title.text)
      end
    EOF
    assert_equal("title\nWake up to WonderWidgets!\nOverview\n", IO.read(CSV))
  end

  def test_rate_limit
    # true network requests call sleep for timeouts, which interferes with our
    # instrumentation of Kernel#sleep
    skip if test_network?

    slept = false

    # change Kernel#sleep to not really sleep!
    Kernel.send(:alias_method, :old_sleep, :sleep)
    Kernel.send(:define_method, :sleep) do |_duration|
      slept = true
    end

    sinew.runtime_options.rate_limit = 1
    sinew.dsl.get('http://httpbin.org/html')
    sinew.dsl.get('http://httpbin.org/get')
    assert(slept)

    # restore old Kernel#sleep
    Kernel.send(:alias_method, :sleep, :old_sleep)
    Kernel.send(:undef_method, :old_sleep)
  end

  def test_output_limit
    sinew.options[:limit] = 3
    run_recipe <<~'EOF'
      (1..10).each { |i| csv_emit(i: i) }
    EOF
    assert_equal "i\n1\n2\n3\n", IO.read(CSV)
  end
end
