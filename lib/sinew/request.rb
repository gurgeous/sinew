require 'digest/md5'
require 'httparty'
require 'htmlentities'

#
# Process a single HTTP request. Mostly a wrapper around HTTParty.
#

module Sinew
  class Error < StandardError; end

  class Request
    HTML_ENTITIES = HTMLEntities.new
    VALID_METHODS = %w[get post patch put delete head options].freeze

    attr_reader :sinew, :method, :uri, :options, :cache_key

    # Options are largely compatible with HTTParty, except for :method.
    def initialize(sinew, method, url, options = {})
      @sinew = sinew
      @method = method
      @options = options.dup
      @uri = parse_url(url)
      @cache_key = calculate_cache_key
    end

    def proxy
      @proxy ||= begin
        if proxies = sinew.options[:proxy]
          proxies.split(',').sample
        end
      end
    end

    # run the request, return the result
    def perform
      validate!

      party_options = options.dup

      # merge proxy
      if proxy = self.proxy
        addr, port = proxy.split(':')
        party_options[:http_proxyaddr] = addr
        party_options[:http_proxyport] = port || 80
      end

      # now merge runtime_options
      party_options = party_options.merge(sinew.runtime_options.httparty_options)

      # merge headers
      headers = sinew.runtime_options.headers
      headers = headers.merge(party_options[:headers]) if party_options[:headers]
      party_options[:headers] = headers

      party_response = HTTParty.send(method, uri, party_options)
      Response.from_network(self, party_response)
    end

    # We accept sloppy urls and attempt to clean them up
    def parse_url(url)
      s = url

      # remove entities
      s = HTML_ENTITIES.decode(s)

      # fix a couple of common encoding bugs
      s = s.gsub(' ', '%20')
      s = s.gsub("'", '%27')

      # append query manually (instead of letting HTTParty handle it) so we can
      # include it in cache_key
      query = options.delete(:query)
      if query.present?
        q = HTTParty::HashConversions.to_params(query)
        separator = s.include?('?') ? '&' : '?'
        s = "#{s}#{separator}#{q}"
      end

      URI.parse(s)
    end
    protected :parse_url

    def calculate_cache_key
      dir = pathify(uri.host)

      body_key = if body.is_a?(Hash)
        HTTParty::HashConversions.to_params(body)
      else
        body&.dup
      end

      # Build key, as a hash for before_generate_cache_key. Note that :scheme is
      # just a placeholder in case someone wants to add it for real, so that
      # it'll appear in the correct order. We remove the placerholder after we
      # call the proc.
      key = {
        method: method.dup,
        scheme: 'placeholder',
        path: uri.path,
        query: uri.query,
        body: body_key,
      }

      args = [ key ]
      if sinew.runtime_options.before_generate_cache_key.arity == 2
        args << uri
      end
      key = sinew.runtime_options.before_generate_cache_key.call(*args)

      # strip defaults
      key.delete(:scheme) if key[:scheme] == 'placeholder'
      key.delete(:method) if key[:method] == 'get'

      # pull out the values, join and pathify
      path = key.values.select(&:present?).join(',')
      path = pathify(path)

      # shorten long paths
      if path.length > 250
        path = Digest::MD5.hexdigest(path)
      end

      "#{dir}/#{path}"
    end
    protected :calculate_cache_key

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
