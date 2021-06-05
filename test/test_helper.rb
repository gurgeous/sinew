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

    protected

    def test_html
      IO.read("#{__dir__}/test.html")
    end

    def recipe(code)
      code = <<~EOF
        class Recipe < Sinew::Base
          def run
            #{code}
          end
        end
      EOF

      "#{@tmpdir}/recipe.rb".tap do
        IO.write(_1, code)
      end
    end
  end
end
