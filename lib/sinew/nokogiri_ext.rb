require "nokogiri"

# modify NodeSet to join with SPACE instead of empty string
module Nokogiri
  module XML
    class NodeSet
      alias_method :old_inner_html, :inner_html
      alias_method :old_inner_text, :inner_text

      def inner_text
        map(&:inner_text).join(" ")
      end

      def inner_html(*args)
        map { _1.inner_html(*args) }.join(" ")
      end
    end
  end
end
