require 'English'
require 'sinew'
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/minitest'
require 'webmock/minitest'

# a hint to sinew, so that it'll do things like set rate limit to zero
ENV['SINEW_TEST'] = '1'

module MiniTest
  class Test
    def setup
      @tmpdir = Dir.mktmpdir('sinew')
    end

    def teardown
      FileUtils.rm_rf(@tmpdir)
      WebMock.reset!
    end
  end
end
