require "helper"

module Sinew
  class TestCurler < TestCase
    def setup
      # create TMP dir
      FileUtils.rm_rf(TMP) if File.exists?(TMP)
      FileUtils.mkdir_p(TMP)

      # curler, pointed at TMP
      @curler = Curler.new(dir: TMP, verbose: false)
    end

    #
    # tests
    #

    def test_200
      Util.stub(:run, mock_curl_200) do
        path = @curler.get("http://www.example.com")
        assert_equal(HTML, File.read(path))
      end
    end

    def test_500
      assert_raises(Curler::Error) do
        Util.stub(:run, mock_curl_500) do
          @curler.get("http://www.example.com")
        end
      end
    end

    def test_cached
      Util.stub(:run, mock_curl_200) do
        assert_equal(HTML, File.read(@curler.get("http://www.example.com")))
      end
      # the file is cached, so this shouldn't produce an error
      Util.stub(:run, mock_curl_500) do
        @curler.get("http://www.example.com")
      end
    end

    def test_302
      Util.stub(:run, mock_curl_302) do
        @curler.get("http://www.example.com")
        assert_equal("http://www.gub.com", @curler.url)
      end
    end

    def test_rate_limit
      slept = false
      
      # change Kernel#sleep to not really sleep!
      Kernel.send(:alias_method, :old_sleep, :sleep)
      Kernel.send(:define_method, :sleep) do |x|
        slept = true
      end

      Util.stub(:run, mock_curl_200) do
        @curler.get("http://www.example.com/1")
        @curler.get("http://www.example.com/2")
      end
      assert(slept)

      # restore old Kernel#sleep
      Kernel.send(:alias_method, :sleep, :old_sleep)
      Kernel.send(:undef_method, :old_sleep)
    end
  end
end
