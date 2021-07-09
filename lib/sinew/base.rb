require 'amazing_print'
require 'faraday-encoding'
require 'faraday/logging/formatter'
require 'faraday-rate_limiter'
require 'httpdisk'

module Sinew
  # Sinew base class, for in standalone scripts or via the sinew binary.
  class Base
    attr_reader :csv, :mutex, :options

    def initialize(opts = {})
      @mutex = Mutex.new

      #
      # defaults for Sloptions
      #

      # default :rate_limit, typically 1
      default_rate_limit = ENV['SINEW_TEST'] ? 0 : 1

      #
      # note: uses HTTPDisk::Sloptions
      #

      @options = HTTPDisk::Sloptions.parse(opts) do
        # cli
        _1.integer :limit
        _1.integer :timeout, default: 30
        _1.boolean :silent
        _1.on :proxy, type: [:string, Array]
        _1.boolean :verbose

        # httpdisk
        _1.string :dir, default: File.join(ENV['HOME'], '.sinew')
        _1.integer :expires
        _1.boolean :force
        _1.boolean :force_errors
        _1.array :ignore_params

        # more runtime options
        _1.hash :headers
        _1.boolean :insecure
        _1.string :output, required: true
        _1.hash :params
        _1.float :rate_limit, default: default_rate_limit
        _1.integer :retries, default: 2
        _1.on :url_prefix, type: [:string, URI]
        _1.boolean :utf8, default: true
      end

      @csv = CSV.new(opts[:output])
    end

    #
    # requests
    #

    # http get, returns a Response
    def get(url, params = nil, headers = nil)
      faraday_response = faraday.get(url, params, headers) do
        _1.options[:proxy] = random_proxy
      end
      Response.new(faraday_response)
    end

    # http post, returns a Response. Defaults to form body type.
    def post(url, body = nil, headers = nil)
      faraday_response = faraday.post(url, body, headers) do
        _1.options[:proxy] = random_proxy
      end
      Response.new(faraday_response)
    end

    # http post json, returns a Response
    def post_json(url, body = nil, headers = nil)
      body = body.to_json
      headers = (headers || {}).merge('Content-Type' => 'application/json')
      post(url, body, headers)
    end

    # Faraday connection for this recipe
    def faraday
      mutex.synchronize do
        @faraday ||= create_faraday
      end
    end

    #
    # httpdisk
    #

    # Returns true if request is cached. Defaults to form body type.
    def cached?(method, url, params = nil, body = nil)
      status = status(method, url, params, body)
      status[:status] != 'miss'
    end

    # Remove cache file, if any. Defaults to form body type.
    def uncache(method, url, params = nil, body = nil)
      status = status(method, url, params, body)
      path = status[:path]
      File.unlink(path) if File.exist?(path)
    end

    # Check httpdisk status for this request. Defaults to form body type.
    def status(method, url, params = nil, body = nil)
      # if hash, default to url encoded form
      # see lib/faraday/request/url_encoded.rb
      if body.is_a?(Hash)
        body = Faraday::Utils::ParamsHash[body].to_query
      end

      env = Faraday::Env.new.tap do
        _1.method = method.to_s.downcase.to_sym
        _1.request_headers = {}
        _1.request_body = body
        _1.url = faraday.build_url(url, params)
      end
      httpdisk.status(env)
    end

    #
    # csv
    #

    # Output a csv header. This usually happens automatically, but you can call
    # this method directly to ensure a consistent set of columns.
    def csv_header(*columns)
      csv.start(columns.flatten)
    end

    # Output a csv row. Row should be any object that can turn into a hash - a
    # hash, OpenStruct, etc.
    def csv_emit(row)
      row = row.to_h
      mutex.synchronize do
        # header if necessary
        csv_header(row.keys) if !csv.started?

        # emit
        print = csv.emit(row)
        puts print.ai if options[:verbose]

        # this is caught by Sinew::Main
        if csv.count == options[:limit]
          raise LimitError
        end
      end
    end

    #
    # stdout
    #

    RESET = "\e[0m".freeze
    RED = "\e[1;37;41m".freeze
    GREEN = "\e[1;37;42m".freeze

    # Print a nice green banner.
    def banner(msg, color: GREEN)
      msg = "#{msg} ".ljust(72, ' ')
      msg = "[#{Time.new.strftime('%H:%M:%S')}] #{msg}"
      msg = "#{color}#{msg}#{RESET}" if $stdout.tty?
      puts msg
    end

    # Print a scary red banner and exit.
    def fatal(msg)
      banner(msg, color: RED)
      exit 1
    end

    protected

    # Return a random proxy.
    def random_proxy
      return if !options[:proxy]

      proxies = options[:proxy]
      proxies = proxies.split(',') if !proxies.is_a?(Array)
      proxies.sample
    end

    # Create the Faraday connection for making requests.
    def create_faraday
      faraday_options = options.slice(:headers, :params)
      if options[:insecure]
        faraday_options[:ssl] = { verify: false }
      end
      Faraday.new(nil, faraday_options) do
        # options
        if options[:url_prefix]
          _1.url_prefix = options[:url_prefix]
        end
        _1.options.timeout = options[:timeout]

        #
        # middleware that runs on both disk/network requests
        #

        # cookie middleware
        _1.use :cookie_jar

        # auto-encode form bodies
        _1.request :url_encoded

        # Before httpdisk so each redirect segment is cached
        # Keep track of redirect status for logger
        _1.response :follow_redirects, callback: ->(_old_env, new_env) { new_env[:redirect] = true }

        #
        # httpdisk
        #

        httpdisk_options = options.slice(:dir, :expires, :force, :force_errors, :ignore_params, :utf8)
        _1.use :httpdisk, httpdisk_options

        #
        # middleware below only used it httpdisk uses the network
        #

        # rate limit
        rate_limit = options[:rate_limit]
        _1.request :rate_limiter, interval: rate_limit

        # After httpdisk so that only non-cached requests are logged.
        # Before retry so that we don't log each retry attempt.
        _1.response :logger, nil, formatter: Middleware::LogFormatter if !options[:silent]

        retry_options = {
          max_interval: rate_limit, # very important, negates Retry-After: 86400
          max: options[:retries],
          methods: %w[delete get head options patch post put trace],
          retry_statuses: (500..600).to_a,
          retry_if: ->(_env, _err) { true },
        }
        _1.request :retry, retry_options
      end
    end

    # find connection's httpdisk instance
    def httpdisk
      @httpdisk ||= begin
        app = faraday.app
        app = app.app until app.is_a?(HTTPDisk::Client)
        app
      end
    end
  end
end
