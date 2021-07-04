require 'test_helper'

class TestMain < MiniTest::Test
  def test_blackbox
    # --help (fast)
    output = `bin/sinew --help`
    assert $CHILD_STATUS.success?
    assert_match(/From httpdisk/i, output)

    # real simple end-to-end test, no network required
    recipe = recipe('sinew.csv_emit(a: 1)')
    output = `bin/sinew #{recipe}`
    assert $CHILD_STATUS.success?
    assert_match(/Done/i, output)
  end

  def test_bad_options
    [
      '',
      'a.sinew b.sinew',
      '--expires 1z ignore.sinew',
      'not_found.sinew',
    ].each do |args|
      assert_raises { sinew(args) }
    end
  end

  def test_httpdisk_options
    recipe = recipe('#nop')
    main = main("--dir xyz --expires 1h --force --force-errors #{recipe}")
    httpdisk_options = main.sinew.options.slice(:dir, :expires, :force, :force_errors)
    assert_equal 'xyz', httpdisk_options[:dir]
    assert_equal 60 * 60, httpdisk_options[:expires]
    assert_equal true, httpdisk_options[:force]
    assert_equal true, httpdisk_options[:force_errors]
  end

  def test_limit
    recipe = recipe('100.times { sinew.csv_emit(a: 1) }')
    main = main("--limit 50 --silent #{recipe}")
    main.run
    assert_equal 50, main.sinew.csv.count
  end

  def test_proxy
    recipe = recipe('#nop')
    main = main("--proxy boom:123,boom:123 #{recipe}")
    assert_equal 'boom:123', main.sinew.send(:random_proxy)
  end

  def test_timeout
    recipe = recipe('#nop')
    main = main("--timeout 123 #{recipe}")
    assert_equal 123, main.sinew.faraday.options.timeout
  end

  def test_silent
    recipe = recipe('3.times { sinew.csv_emit(a: 1) } ; puts "hi" ')
    main = main("--silent #{recipe}")
    assert_output("hi\n") { main.run }
  end

  def test_verbose
    recipe = recipe('sinew.csv_emit(a: 1)')
    main = main("--verbose #{recipe}")
    # amazing print adds ansi colors, so use .* to skip them
    assert_output(/:a.*=>.*"1"/) { main.run }
  end

  protected

  def main(args)
    args = args.split
    args += ['--dir', @tmpdir] if !args.include?('--dir')
    Sinew::Main.new(Sinew::Args.slop(args))
  end
end
