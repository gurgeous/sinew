require "helper"

module Sinew
  class TestCurler < TestCase
    def setup
      # create TMP dir
      FileUtils.rm_rf(TMP) if File.exists?(TMP)
      FileUtils.mkdir_p(TMP)

      # curler, pointed at TMP
      @curler = Curler.new(dir: TMP, verbose: false)

      # mock curl runs
      @curl_200 = Proc.new do |cmd, args|
        fake_curl(args, HTML, "HTTP/1.1 200 OK")
      end
      @curl_302 = Proc.new do |cmd, args|
        fake_curl(args, "", "HTTP/1.1 302 Moved Temporarily\r\nLocation: http://www.gub.com")
      end
      @curl_500 = Proc.new do |cmd, args|
        raise Util::RunError, "curl error"
      end
    end

    def fake_curl(args, body, head)
      File.write(args[args.index("--output") + 1], body)
      File.write(args[args.index("--dump-header") + 1], "#{head}\r\n\r\n")
    end

    #
    # tests
    #

    def test_200
      Util.stub(:run, @curl_200) do
        path = @curler.get("http://www.example.com")
        assert_equal(HTML, File.read(path))
      end
    end

    def test_500
      assert_raises(Curler::Error) do
        Util.stub(:run, @curl_500) do
          @curler.get("http://www.example.com")
        end
      end
    end

    def test_cached
      Util.stub(:run, @curl_200) do
        assert_equal(HTML, File.read(@curler.get("http://www.example.com")))
      end
      # the file is cached, so this shouldn't produce an error
      Util.stub(:run, @curl_500) do
        @curler.get("http://www.example.com")
      end
    end

    def test_302
      Util.stub(:run, @curl_302) do
        @curler.get("http://www.example.com")
        assert_equal("http://www.gub.com", @curler.url)
      end
    end
  end
end
