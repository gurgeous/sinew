require_relative 'test_helper'

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
end
