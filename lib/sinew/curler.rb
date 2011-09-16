require "curb"
require "uri"

# sudo apt-get install libcurl4-openssl-dev

module Sinew
  class Curler
    class Error < StandardError ; end
    
    DEFAULT_OPTIONS = {
      :cache_errors => true,
      :user_agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0)",
      :max_time => 30,
      :retry => 3,
      :verbose => 2,
    }
    
    attr_reader :url, :uri, :root

    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
      @last_request = Time.at(0)

      @options[:verbose] = 1 if @options[:verbose] == true
      @options[:verbose] = @options[:verbose].to_i

      @root = @options[:dir]
      if !@root
        if File.stat(ENV["HOME"]).writable?
          @root = "#{ENV["HOME"]}/.sinew"
        else
          @root = "/tmp/sinew"
        end
      end

      @curl = Curl::Easy.new
    end

    def get(url)
      curl(url, nil)
    end

    def post(url, body)
      curl(url, body)
    end
    
    def curl(url, body)
      #
      # prepare url/uri and calculate paths
      #

      @uri = url.is_a?(URI) ? url : Curler.url_to_uri(url.to_s)
      @url = @uri.to_s

      path = fullpath(@uri)
      path = "#{path},#{Util.pathify(body)}" if body

      # shorten long paths
      if path.length > 250
        dir, base = File.dirname(path), File.basename(path)
        path = "#{dir}/#{Util.md5(base)}"
      end
      
      head = "#{File.dirname(path)}/head/#{File.basename(path)}"

      if !File.exists?(path)
        verbose(body ? "curl #{@url} (POST)" : "curl #{@url}")
        tmp = "/tmp/curler_#{Util.random_text(6)}"
        tmph = "#{tmp}.head"
        begin
          rate_limit
          begin
            @curl.reset
            @curl.headers["User-Agent"] = @options[:user_agent]
            @curl.timeout = @options[:max_time]
            @curl.follow_location = true
            @curl.max_redirects = 3
            @curl.url = @url
            @curl.post_body = body if body

            # make the request
            nretries = @options[:retry]
            begin
              @curl.perform
            rescue Exception => e
              retry if (nretries -= 1) > 0
              raise e
            end

            # redirects
            if @curl.url != @curl.last_effective_url
              File.open(tmph, "w") { |f| f.puts "Location: #{@curl.last_effective_url}" }
            end

            # save response
            if @options[:compress]
              Zlib::GzipWriter.open(tmp) { |f| f.write(@curl.body_str) }
            else
              File.open(tmp, "w") { |f| f.write(@curl.body_str) }
            end
          rescue Curl::Err::CurlError => e
            message = "#{e.class} #{e.message}"
            # cache the error?
            if @options[:cache_errors]
              File.open(path, "w") { |f| f.puts "" }
              File.open(head, "w") { |f| f.puts "CURLER_ERROR\t#{message}" }
            end
            raise Error, message
          end
          Util.mkdir_if_necessary(File.dirname(path))
          Util.mv(tmp, path)
          if File.exists?(tmph)
            Util.mkdir_if_necessary(File.dirname(head))        
            Util.mv(tmph, head)
          end
        ensure
          Util.rm_if_necessary(tmp)
          Util.rm_if_necessary(tmph)
        end
      else
        verbose("read #{@url}", 2)
      end

      #
      # handle redirects (recalculate @uri/@url)
      #

      if File.exists?(head)
        case File.read(head)
        when /^CURLER_ERROR\t(.*)/
          raise Error, $1
        when /^Location: (.*)/
          @uri = URI.parse($1)
          @url = @uri.to_s
          verbose(" => #{@url}", 2)
        end
      end
      
      path
    end
    
    def verbose(s, level = 1)
      $stderr.puts s if @options[:verbose] >= level
    end

    #
    # helpers
    #

    def fullpath(uri)
      "#{@root}/#{Curler.uri_to_path(uri)}"  
    end

    def uncache!(url)
      Util.rm_if_necessary("#{@root}/#{Curler.url_to_path(url)}")
    end

    def self.url_to_uri(url)
      url = url.gsub(" ", "%20")
      url = url.gsub("'", "%27")
      URI.parse(url)
    end
    
    def self.url_to_path(url)
      uri_to_path(url_to_uri(url))
    end

    def self.uri_to_path(uri)
      s = uri.path
      s = "#{s}?#{uri.query}" if uri.query
      "#{Util.pathify(uri.host || "local")}/#{Util.pathify(s)}"
    end
    
    def rate_limit
      now = Time.now
      sleep = (@last_request + 1) - now
      sleep(sleep) if sleep > 0
      @last_request = now
    end
  end
end
