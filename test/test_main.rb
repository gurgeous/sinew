require_relative 'test_helper'

require 'base64'

class TestMain < MiniTest::Test
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

  def test_gunzip
    body = Base64.decode64('H4sICBRI61oAA2d1Yi50eHQASy9N4gIAJlqRYgQAAAA=')
    body = Sinew::Response.process_body(OpenStruct.new(body: body))
    assert_equal 'gub', body.strip
  end
end
