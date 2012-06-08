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
      "--force-output" => "yes",    
      "-f" => "/dev/null",
    }

    XML_ENTITIES = { "&"=>"&amp;", "<"=>"&lt;", ">"=>"&gt;", "'"=>"&apos;", '"'=>"&quot;" }
    XML_ENTITIES_INV = XML_ENTITIES.invert
    COMMON_ENTITIES_INV = XML_ENTITIES_INV.merge(
                                                 "&frac12;" => "1/2",
                                                 "&frac14;" => "1/4",
                                                 "&frac34;" => "3/4",
                                                 "&ldquo;" => '"',
                                                 "&lsquo;" => "'",
                                                 "&mdash;" => "-",
                                                 "&nbsp;" => " ",
                                                 "&ndash;" => "-",
                                                 "&rdquo;" => '"',
                                                 "&rsquo;" => "'",
                                                 "&tilde;" => "~",
                                                 "&#34;" => '"',
                                                 "&#39;" => "'",
                                                 "&#160;" => " ",
                                                 "&#8232;" => "\n"
                                                 )
    
    #
    # tidy/clean
    #
    
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

    #
    # untag/unent
    #

    def xml_escape(s)
      s.gsub(/[&<>'"]/) { |i| XML_ENTITIES[i] }
    end

    def xml_unescape(s)
      s.gsub(/&(amp|lt|gt|apos|quot);/) { |i| XML_ENTITIES_INV[i] }
    end

    def untag(s)
      s.gsub(/<[^>]+>/, " ")    
    end

    def unent(s)
      s.gsub(/&#?[a-z0-9]{2,};/) { |i| COMMON_ENTITIES_INV[i] }
    end
  end
end
