require "active_support/core_ext"
require "test/unit"
require "sinew"

module Sinew
  class TestCase < Test::Unit::TestCase
    TMP = "/tmp/_test_sinew"
    HTML_FILE = File.expand_path("#{File.dirname(__FILE__)}/test.html")
    HTML = File.read(HTML_FILE)

    #
    # for mocking curl
    #

    def mock_curl_200
      Proc.new do |cmd, args|
        mock_curl(args, HTML, "HTTP/1.1 200 OK")
      end
    end

    def mock_curl_302
      Proc.new do |cmd, args|
        mock_curl(args, "", "HTTP/1.1 302 Moved Temporarily\r\nLocation: http://www.gub.com")
      end
    end

    def mock_curl_500
      Proc.new do |cmd, args|
        raise Util::RunError, "curl error"
      end
    end

    def mock_curl(args, body, head)
      File.write(args[args.index("--output") + 1], body)
      File.write(args[args.index("--dump-header") + 1], "#{head}\r\n\r\n")
    end
  end
end

#
# from MiniTest, but not in the gem yet
#

class Object
  def stub name, val_or_callable, &block
    new_name = "__minitest_stub__#{name}"

    metaclass = class << self; self; end
    metaclass.send :alias_method, new_name, name
    metaclass.send :define_method, name do |*args|
      if val_or_callable.respond_to? :call then
        val_or_callable.call(*args)
      else
        val_or_callable
      end
    end

    yield
  ensure
    metaclass.send :undef_method, name
    metaclass.send :alias_method, name, new_name
    metaclass.send :undef_method, new_name
  end
end
