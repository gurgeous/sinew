require "active_support/core_ext"
require "test/unit"
require "sinew"

module Sinew
  class TestCase < Test::Unit::TestCase
    TMP = "/tmp/_test_curler"
    HTML_FILE = File.expand_path("#{File.dirname(__FILE__)}/test.html")
    HTML = File.read(HTML_FILE)
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
