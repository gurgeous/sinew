require 'delegate'
require 'hashie/mash'
require 'json'
require 'nokogiri'
require 'sterile'

module Sinew
  class Response < SimpleDelegator
    def html
      @html ||= body.dup.tap do
        # squish
        _1.strip!
        _1.gsub!(/\s+/, ' ')

        # kill whitespace around tags
        _1.gsub!(/ ?<([^>]+)> ?/, '<\\1>')
      end
    end

    def json
      @json ||= JSON.parse(body, symbolize_names: true)
    end

    def mash
      @mash ||= Hashie::Mash.new(json)
    end

    def noko
      @noko ||= Nokogiri::HTML(html)
    end

    def xml
      @xml ||= Nokogiri::XML(html)
    end

    def url
      env.url
    end
  end
end
