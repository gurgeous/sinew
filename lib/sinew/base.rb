require 'amazing_print'
require 'faraday-encoding'
require 'faraday/logging/formatter'
require 'faraday-rate_limiter'
require 'httpdisk'

module Sinew
  # Base class for Sinew recipes. Some effort was made to avoid naming
  # collisions for subclasses.
  class Base
    attr_reader :sinew_csv, :sinew_mutex, :sinew_options

    def initialize(options = {})
      @sinew_mutex = Mutex.new

      #
      # defaults for Sloptions
      #

      # default :rate_limit, typically 1
      default_rate_limit = ENV['SINEW_TEST'] ? 0 : 1

      # default .csv file for :output
      default_output = begin
        src = method(:run).source_location.first
        dst = File.join(File.dirname(src), "#{File.basename(src, File.extname(src))}.csv")
        dst = dst.sub(%r{^./}, '') # nice to clean this up
        dst
      end

      #
      # note: uses HTTPDisk::Sloptions
      #

      @sinew_options = HTTPDisk::Sloptions.parse(options) do
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
        _1.string :output, default: default_output
        _1.hash :params
        _1.integer :rate_limit, default: default_rate_limit
        _1.integer :retries, default: 2
        _1.on :url_prefix, type: [:string, URI]
      end

      @sinew_csv = CSV.new(sinew_options[:output])
    end

    # main entry point, used by Sinew::Main
    def run
      raise 'subclass must override run'
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
      raise 'forgot to call super from initialize' if !sinew_options

      sinew_mutex.synchronize do
        @faraday ||= create_faraday
      end
    end

    #
    # httpdisk
    #

    # find the httpdisk instance
    def httpdisk
      @httpdisk ||= begin
        app = faraday.app
        app = app.app until app.is_a?(HTTPDisk::Client)
        app
      end
    end

    # Returns true if request is cached. If body is a hash, it will be form
    # encoded.
    def httpdisk_cached?(method, url, params = nil, body = nil)
      status = httpdisk_status(method, url, params, body)
      status[:status] != 'miss'
    end

    # Remove cache file, if any. If body is a hash, it will be form encoded.
    def httpdisk_uncache(method, url, params = nil, body = nil)
      status = httpdisk_status(method, url, params, body)
      path = status[:path]
      File.unlink(path) if File.exist?(path)
    end

    # Check httpdisk status for this request. If body is a hash, it will be form encoded.
    def httpdisk_status(method, url, params = nil, body = nil)
      # if body is a hash, convert to url encoded form
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

    # Ouptut a csv header. This usually happens automatically, but you can call
    # this method directly to ensure a consistent set of columns.
    def csv_header(*columns)
      sinew_csv.start(columns.flatten)
    end

    # Output a csv row. Row should be any object that can turn into a hash - a
    # hash, OpenStruct, etc.
    def csv_emit(row)
      row = row.to_h
      sinew_mutex.synchronize do
        # header if necessary
        csv_header(row.keys) if !sinew_csv.started?

        # emit
        print = sinew_csv.emit(row)
        puts print.ai if sinew_options[:verbose]

        # this is caught by Sinew::Main
        if sinew_csv.count == sinew_options[:limit]
          raise LimitError
        end
      end
    end

    #
    # header/footer
    #

    # Called by Sinew::Main to output the header.
    def sinew_header
      sinew_banner("Writing to #{sinew_csv.path}...")
    end

    # Called by Sinew::Main to output the footer.
    def sinew_footer(elapsed)
      count = sinew_csv.count

      if count == 0
        sinew_banner(format('Done in %ds. Nothing written.', elapsed))
        return
      end

      # summary
      msg = format('Done in %ds. Wrote %d rows to %s. Summary:', elapsed, count, sinew_csv.path)
      sinew_banner(msg)

      # tally
      tally = sinew_csv.tally.sort_by { [-_2, _1.to_s] }.to_h
      len = tally.keys.map { _1.to_s.length }.max
      fmt = "  %-#{len + 1}s %7d/%-7d %5.1f%%\n"
      tally.each do
        printf(fmt, _1, _2, count, _2 * 100.0 / count)
      end
    end

    #
    # stdout
    #

    RESET = "\e[0m".freeze
    RED = "\e[1;37;41m".freeze
    GREEN = "\e[1;37;42m".freeze

    # Print a nice green banner.
    def sinew_banner(msg, color: GREEN)
      msg = "#{msg} ".ljust(72, ' ')
      msg = "[#{Time.new.strftime('%H:%M:%S')}] #{msg}"
      msg = "#{color}#{msg}#{RESET}" if $stdout.tty?
      puts msg
    end

    # Print a scary red banner and exit.
    def sinew_fatal(msg)
      sinew_banner(msg, color: RED)
      exit 1
    end

    #
    # helpers for finding recipe subclasses
    #

    # used by Sinew::Main
    def self.subclasses
      @@subclasses ||= []
    end

    # this is a Ruby callback
    def self.inherited(subclass)
      super
      subclasses << subclass
    end

    protected

    # Return a random proxy.
    def random_proxy
      return if !sinew_options[:proxy]

      proxies = sinew_options[:proxy]
      proxies = proxies.split(',') if !proxies.is_a?(Array)
      proxies.sample
    end

    # Create the Faraday connection for making requests.
    def create_faraday
      faraday_options = sinew_options.slice(:headers, :params)
      if sinew_options[:insecure]
        faraday_options[:ssl] = { verify: false }
      end
      Faraday.new(nil, faraday_options) do
        # options
        if sinew_options[:url_prefix]
          _1.url_prefix = sinew_options[:url_prefix]
        end
        _1.options.timeout = sinew_options[:timeout]

        #
        # middleware that runs on both disk/network requests
        #

        # cookie middleware
        _1.use :cookie_jar

        # auto-encode form bodies
        _1.request :url_encoded

        # set Ruby string encoding based on Content-Type
        _1.response :encoding

        # Before httpdisk so each redirect segment is cached
        # Keep track of redirect status for logger
        _1.response :follow_redirects, callback: ->(_old_env, new_env) { new_env[:redirect] = true }

        #
        # httpdisk
        #

        httpdisk_options = sinew_options.slice(:dir, :expires, :force, :force_errors, :ignore_params)
        _1.use :httpdisk, httpdisk_options

        #
        # middleware below only used it httpdisk uses the network
        #

        # rate limit
        _1.request :rate_limiter, interval: sinew_options[:rate_limit]

        # After httpdisk so that only non-cached requests are logged.
        # Before retry so that we don't log each retry attempt.
        _1.response :logger, nil, formatter: Middleware::LogFormatter if !sinew_options[:silent]

        retry_options = {
          interval: sinew_options[:rate_limit],
          max: sinew_options[:retries],
          methods: %w[delete get head options patch post put trace],
          retry_statuses: (500..600).to_a,
          retry_if: ->(_env, _err) { true },
        }
        _1.request :retry, retry_options
      end
    end
  end
end
