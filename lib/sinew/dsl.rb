require 'awesome_print'
require 'cgi'

#
# The DSL available to .sinew files.
#

module Sinew
  class DSL
    attr_reader :sinew, :raw, :uri, :elapsed

    def initialize(sinew)
      @sinew = sinew
    end

    def run
      tm = Time.now
      recipe = sinew.options[:recipe]
      instance_eval(File.read(recipe, mode: 'rb'), recipe)
      @elapsed = Time.now - tm
    end

    #
    # request
    #

    def get(url, query = {})
      http('get', url, query: query)
    end

    def post(url, form = {})
      body = form
      headers = {
        'Content-Type' => 'application/x-www-form-urlencoded',
      }
      http('post', url, body: body, headers: headers)
    end

    def post_json(url, json = {})
      body = json.to_json
      headers = {
        'Content-Type' => 'application/json',
      }
      http('post', url, body: body, headers: headers)
    end

    def http(method, url, options = {})
      # reset
      @html = @noko = @json = @url = nil

      # fetch
      response = sinew.http(method, url, options)

      # respond
      @uri = response.uri
      @raw = response.body
    end

    #
    # response
    #

    def html
      @html ||= begin
        s = raw.dup
        # squish!
        s.squish!
        # kill whitespace around tags
        s.gsub!(/ ?<([^>]+)> ?/, '<\\1>')
        s
      end
    end

    def noko
      @noko ||= Nokogiri::HTML(html)
    end

    def json
      @json ||= JSON.parse(raw, symbolize_names: true)
    end

    def url
      uri.to_s
    end

    #
    # csv
    #

    def csv_header(*args)
      sinew.output.header(args)
    end

    def csv_emit(row)
      sinew.output.emit(row)
    end
  end
end
