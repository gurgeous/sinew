require 'delegate'
require 'hashie/mash'
require 'json'
require 'nokogiri'

module Sinew
  # A wrapper around Faraday::Response, with some parsing helpers.
  class Response < SimpleDelegator
    # Like body, but tries to cleanup whitespace around HTML for easier parsing.
    def html
      @html ||= body.dup.tap do
        # squish
        _1.strip!
        _1.gsub!(/\s+/, ' ')

        # kill whitespace around tags
        _1.gsub!(/ ?<([^>]+)> ?/, '<\\1>')
      end
    end

    # Return body as JSON
    def json
      @json ||= JSON.parse(body, symbolize_names: true)
    end

    # Return JSON body as Hashie::Mash
    def mash
      @mash ||= Hashie::Mash.new(json)
    end

    # Return body HTML as Nokogiri document
    def noko
      @noko ||= Nokogiri::HTML(html)
    end

    # Return body XML as Nokogiri document
    def xml
      @xml ||= Nokogiri::XML(html)
    end

    # Return the final URI for the request, after redirects
    def url
      env.url
    end

    # Return the cache diskpath for this response
    def diskpath
      env[:httpdisk_diskpath]
    end

    # Remove cached response from disk, if any
    def uncache
      File.unlink(diskpath) if File.exist?(diskpath)
    end
  end
end
