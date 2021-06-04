require 'nokogiri'

# modify NodeSet to join with SPACE instead of empty string
class Nokogiri::XML::NodeSet
  alias old_inner_html inner_html
  alias old_inner_text inner_text

  def inner_text
    map(&:inner_text).join(' ')
  end

  def inner_html(*args)
    map { |i| i.inner_html(*args) }.join(' ')
  end
end

# text_just_me
class Nokogiri::XML::Node
  def text_just_me
    t = children.find { |i| i.node_type == Nokogiri::XML::Node::TEXT_NODE }
    t&.text
  end
end

class Nokogiri::XML::NodeSet
  def text_just_me
    map(&:text_just_me).join(' ')
  end
end
