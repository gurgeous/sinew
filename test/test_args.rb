require 'test_helper'

class TestArgs < MiniTest::Test
  def test_bad_options
    [
      '',
      'a.rb b.rb',
      '--expires 1z ignore.rb',
      'not_found.rb',
    ].each do |args|
      assert_raises { sinew(args) }
    end
  end

  def test_httpdisk_options
    recipe = recipe('#nop')
    sinew = sinew("--dir xyz --expires 1h --force --force-errors #{recipe}")
    httpdisk_options = sinew.recipe.sinew_options.slice(:dir, :expires, :force, :force_errors)
    assert_equal 'xyz', httpdisk_options[:dir]
    assert_equal 60 * 60, httpdisk_options[:expires]
    assert_equal true, httpdisk_options[:force]
    assert_equal true, httpdisk_options[:force_errors]
  end

  def test_limit
    recipe = recipe('100.times { csv_emit(a: 1) }')
    sinew = sinew("--limit 50 --silent #{recipe}")
    sinew.run
    assert_equal 50, sinew.recipe.sinew_csv.count
  end

  def test_proxy
    recipe = recipe('#nop')
    sinew = sinew("--proxy boom:123 #{recipe}")
    assert_equal 'boom:123', sinew.recipe.send(:random_proxy)
  end

  def test_timeout
    recipe = recipe('#nop')
    sinew = sinew("--timeout 123 #{recipe}")
    assert_equal 123, sinew.recipe.faraday.options.timeout
  end

  def test_silent
    recipe = recipe('3.times { csv_emit(a: 1) } ; puts "hi" ')
    sinew = sinew("--silent #{recipe}")
    assert_output("hi\n") { sinew.run }
  end

  def test_verbose
    recipe = recipe('csv_emit(a: 1)')
    sinew = sinew("--verbose #{recipe}")
    # amazing print adds ansi colors, so use .* to skip them
    assert_output(/:a.*=>.*"1"/) { sinew.run }
  end

  protected

  def sinew(args)
    args = args.split
    args += ['--dir', @tmpdir] if !args.include?('--dir')
    Sinew::Main.new(Sinew::Args.slop(args))
  end
end
