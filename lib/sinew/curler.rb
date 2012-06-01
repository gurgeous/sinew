require "uri"

module Sinew
  class Curler
    class Error < StandardError ; end
    
    DEFAULT_OPTIONS = {
      :cache_errors => true,
      :max_time => 30,
      :retry => 3,
      :verbose => true,
    }
    
    attr_reader :url, :uri, :root

    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
      @curl_args = ["--silent", "--fail", "--user-agent", @options[:user_agent], "--max-time", @options[:max_time], "--retry", @options[:retry], "--location", "--max-redirs", "3"]
      @last_request = Time.at(0)      

      @root = @options[:dir]
      if !@root
        if File.exists?(ENV["HOME"]) && File.stat(ENV["HOME"]).writable?
          @root = "#{ENV["HOME"]}/.sinew"
        else
          @root = "/tmp/sinew"
        end
      end
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
          Util.mkdir_if_necessary(File.dirname(path))
          Util.mkdir_if_necessary(File.dirname(head))        
          begin
            command = []
            command += @curl_args
            if body
              command += ["--data-binary", body]
              command += ["--header", "Content-Type: application/x-www-form-urlencoded"]
            end
            command += ["--output", tmp]
            command += ["--dump-header", tmph]
            command << @url
            
            Util.run("curl", command)

            # empty response?
            if !File.exists?(tmp)
              Util.touch(tmp)
              Util.touch(tmph)            
            end
          rescue Util::RunError => e
            message = "curl error"
            if e.message =~ /(\d+)$/
              message = "#{message} (#{$1})"
            end
            
            # cache the error?
            if @options[:cache_errors]
              File.open(path, "w") { |f| f.puts "" }
              File.open(head, "w") { |f| f.puts "CURLER_ERROR\t#{message}" }
            end
            
            raise Error, message
          end
          Util.mv(tmp, path)
          Util.mv(tmph, head)
        ensure
          Util.rm_if_necessary(tmp)
          Util.rm_if_necessary(tmph)
        end
      end
      
      #
      # handle redirects (recalculate @uri/@url)
      #

      if File.exists?(head)
        head_contents = File.read(head)
        # handle cached errors
        if head_contents =~ /^CURLER_ERROR\t(.*)/
          raise Error, $1
        end
        original = @uri
        head_contents.scan(/\A(HTTP\/\d\.\d (\d+).*?\r\n\r\n)/m) do |i|
          headers, code = $1, $2
          if code =~ /^3/
            if redir = headers[/^Location: ([^\r\n]+)/, 1]
              @uri += redir
              @url = @uri.to_s
            end
          end
        end
        # kill unnecessary head files
        if original == @uri
          Util.rm(head)
        end
      end
      
      path
    end
    
    def verbose(s)
      $stderr.puts s if @options[:verbose]
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
      "#{Util.pathify(uri.host)}/#{Util.pathify(s)}"
    end
    
    def rate_limit
      sleep = (@last_request + 1) - Time.now
      sleep(sleep) if sleep > 0
      @last_request = Time.now
    end
  end
end
