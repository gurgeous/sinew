require "active_support/core_ext"
require "set"

module Sinew
  module TextUtil
    extend self

    ATTRS_KEEP = Set.new %w(a img iframe)
    TIDY_OPTIONS = {
      "-asxml" => nil,
      "-bare" => nil,
      "-quiet" => nil,
      "-utf8" => nil,    
      "-wrap" =>  0,
      "--doctype" => "omit",
      "--hide-comments" => "yes",
      "--numeric-entities" => "no",
      "--preserve-entities" => "yes",
      "--force-output" => "yes",    
      "-f" => "/dev/null",
    }
    
    def html_tidy(s)
      # run tidy
      args = TIDY_OPTIONS.map { |k, v| "#{k} #{v}" }.join(" ")
      s = IO.popen("tidy #{args}", "rb+") do |f|
        f.write(s)
        f.close_write
        f.read
      end
      raise "could not run tidy" if ($? >> 8) > 2

      # now kill some tags
      s.sub!(/<html\b[^>]+>/, "<html>")
      s.gsub!(/<\/?(meta|link)\b[^>]*>/m, "")
      s.gsub!(/<(style|script)\b[^>]*(\/>|>.*?<\/\1\b>)/m, "")    
      s.gsub!(/<\?[^>]*>/m, "")
      s.squish!

      # kill whitespace around tags
      s.gsub!(/ ?<([^>]+)> ?/, "<\\1>")
      
      s
    end

    def html_clean(s)
      html_clean_from_tidy(html_tidy(s))
    end

    def html_clean_from_tidy(s)
      # then kill most attrs
      s = s.dup
      s.gsub!(/<([^\s>]+)[^>]*?(\/)?>/) do |i|
        ATTRS_KEEP.include?($1) ? i : "<#{$1}#{$2}>"
      end
      s
    end
  end
end
