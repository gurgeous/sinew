require 'amazing_print'
require 'faraday-encoding'
require 'faraday/logging/formatter'
require 'faraday-rate_limiter'
require 'httpdisk'

module Sinew
  class Base
    # these use a sinew_xxx prefix to avoid collisions
    attr_reader :sinew_csv, :sinew_mutex, :sinew_options

    def initialize(options = {})
      @sinew_csv = CSV.new(options[:recipe] || method(:run).source_location.first)
      @sinew_mutex = Mutex.new

      # borrow HTTPDisk::Sloptions for parsing options
      @sinew_options = HTTPDisk::Sloptions.parse(options) do
        # cli
        _1.integer :limit
        _1.integer :max_time, default: 30
        _1.boolean :silent
        _1.on :proxy, type: [:string, Array]
        _1.boolean :verbose

        # httpdisk
        _1.string :dir, default: File.join(ENV['HOME'], '.sinew')
        _1.integer :expires
        _1.boolean :force
        _1.boolean :force_errors
        _1.array :ignore_params

        # more handy options
        _1.hash :headers
        _1.boolean :insecure
        _1.hash :params
        _1.integer :rate_limit, default: 1
        _1.integer :retries, default: 2
        _1.on :url_prefix, type: [:string, URI]
      end
    end

    def run
      raise 'subclass must override run'
    end

    #
    # requests
    #

    def get(url, params = nil, headers = nil)
      faraday_response = faraday.get(url, params, headers) do
        _1.options[:proxy] = random_proxy
      end
      Response.new(faraday_response)
    end

    def post(url, body = nil, headers = nil)
      faraday_response = faraday.post(url, body, headers) do
        _1.options[:proxy] = random_proxy
      end
      Response.new(faraday_response)
    end

    def post_json(url, body = nil, headers = nil)
      body = body.to_json
      headers = (headers || {}).merge("Content-Type" => 'application/json')
      post(url, body, headers)
    end

    def faraday
      raise 'forgot to call super from initialize' if !sinew_options

      sinew_mutex.synchronize do
        @faraday ||= create_faraday
      end
    end

    #
    # csv
    #

    def csv_header(*columns)
      sinew_csv.start(columns.flatten)
    end

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

    def sinew_header
      banner("Writing to #{sinew_csv.path}...")
    end

    def sinew_footer(elapsed)
      count = sinew_csv.count

      if count == 0
        banner(format('Done in %ds. Nothing written.', elapsed))
        return
      end

      # summary
      msg = format('Done in %ds. Wrote %d rows to %s. Summary:', elapsed, count, sinew_csv.path)
      banner(msg)

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

    def banner(msg, color: GREEN)
      msg = "#{msg} ".ljust(72, ' ')
      msg = "[#{Time.new.strftime('%H:%M:%S')}] #{msg}"
      msg = "#{color}#{msg}#{RESET}" if $stdout.tty?
      puts msg
    end

    def fatal(msg)
      banner(msg, color: RED)
      exit 1
    end

    protected

    def random_proxy
      return if !sinew_options[:proxy]

      proxies = sinew_options[:proxy]
      proxies = proxies.split(',') if !proxies.is_a?(Array)
      proxies.sample
    end

    def create_faraday
      faraday_options = sinew_options.slice(:headers, :params, :url_prefix)
      faraday_options[:ssl] = { verify: false } if sinew_options[:insecure]
      Faraday.new(nil, faraday_options) do
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
