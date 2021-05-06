require 'digest/md5'
require 'htmlentities'

#
# Process a single HTTP request.
#

module Sinew
  class Error < StandardError; end

  class Request
    HTML_ENTITIES = HTMLEntities.new
    VALID_METHODS = %w[get post patch put delete head options].freeze

    attr_reader :sinew, :method, :uri, :options

    # Options are largely compatible with HTTParty, except for :method.
    def initialize(sinew, method, url, options = {})
      @sinew = sinew
      @method = method
      @options = options.dup
      @uri = parse_url(url)
    end

    def proxy
      @proxy ||= begin
        if proxies = sinew.options[:proxy]
          proxies.split(',').sample
        end
      end
    end

    # run the request, return the result
    def perform(connection)
      validate!

      headers = sinew.runtime_options.headers
      headers = headers.merge(options[:headers]) if options[:headers]

      body = options.delete(:body)

      # TODO: handle all options
      # party_options = options.dup.merge(sinew.runtime_options.httparty_options)

      fday_response = connection.send(method, uri, body, headers) do
        _1.options[:proxy] = proxy
      end

      Response.from_network(self, fday_response)
    end

    # We accept sloppy urls and attempt to clean them up
    def parse_url(url)
      s = url

      # remove entities
      s = HTML_ENTITIES.decode(s)

      # fix a couple of common encoding bugs
      s = s.gsub(' ', '%20')
      s = s.gsub("'", '%27')

      # append query manually (instead of letting Faraday handle it) for consistent
      # Request#uri and Response#uri
      query = options.delete(:query)
      if query.present?
        q = Faraday::Utils.default_params_encoder.encode(query)
        separator = s.include?('?') ? '&' : '?'
        s = "#{s}#{separator}#{q}"
      end

      URI.parse(s)
    end
    protected :parse_url

    def validate!
      raise "invalid method #{method}" if !VALID_METHODS.include?(method)
      raise "invalid url #{uri}" if uri.scheme !~ /^http/
      raise "can't get with a body" if method == 'get' && body
      raise "Content-Type doesn't make sense without a body" if content_type && !body
    end
    protected :validate!

    def body
      options[:body]
    end
    protected :body

    def headers
      options[:headers]
    end
    protected :headers

    def content_type
      headers && headers['Content-Type']
    end
    protected :content_type

    def form?
      content_type == 'application/x-www-form-urlencoded'
    end
    protected :form?

    def pathify(s)
      # remove leading slash
      s = s.gsub(/^\//, '')
      # .. => comma
      s = s.gsub('..', ',')
      # query separators => comma
      s = s.gsub(/[?\/&]/, ',')
      # ,, => comma
      s = s.gsub(',,', ',')
      # encode invalid path chars
      s = s.gsub(/[^A-Za-z0-9_.,=-]/) do |i|
        hex = i.unpack1('H2')
        "%#{hex}"
      end
      # handle empty case
      s = '_root_' if s.blank?
      # always downcase
      s = s.downcase
      s
    end
    protected :pathify
  end
end
