require "nokogiri" # must be loaded before awesome_print
require "awesome_print"
require "cgi"
require "csv"
require "htmlentities"
require "stringex"

module Sinew
  class Main
    CODER = HTMLEntities.new

    attr_accessor :url, :uri, :raw

    def initialize(options)
      @options = options.dup
      _run if !@options[:test]
    end

    def get(url, params = nil)
      _http(url, params, :get)
    end

    def post(url, params = nil)
      _http(url, params, :post)
    end

    #
    # lazy accessors for cleaned up version
    #

    def html
      @html ||= begin
        s = TextUtil.html_tidy(@raw)
        nelements = @raw.count("<")
        if nelements > 1
          # is there a problem with tidy?
          percent = 100 * s.count("<") / nelements
          if percent < 80
            # bad xml processing instruction? Try fixing it.
            maybe = TextUtil.html_tidy(@raw.gsub(/<\?[^>]*?>/, ""))
            new_percent = 100 * maybe.count("<") / nelements
            if new_percent > 80
              # yes!
              s = maybe
            else
              Util.warning "Hm - it looks like tidy ate some of your file (#{percent}%)" if percent < 90
            end
          end
        end
        s
      end
    end

    def clean
      @clean ||= TextUtil.html_clean_from_tidy(self.html)
    end

    def noko
      @noko ||= Nokogiri::HTML(html)
    end

    #
    # csv
    #

    def csv_header(*args)
      args = args.flatten
      if args.first.is_a?(String)
        file = args.shift
        if file !~ /^\//
          file = "#{File.dirname(@options[:file])}/#{file}"
        end
      else
        file = @options[:file]
      end
      ext = File.extname(file)
      file = ext.empty? ? "#{file}.csv" : file.gsub(ext, ".csv")

      @path = file
      @csv = CSV.open(file, "wb")
      @csv_keys = args
      @csv << @csv_keys
      _banner("Writing to #{@path}...")
    end

    def csv_emit(row, options = {})
      csv_header(row.keys.sort) if !@csv

      print = { }
      row = @csv_keys.map do |i|
        s = _normalize(row[i], i, options)
        print[i] = s if !s.empty?
        s
      end
      $stderr.puts print.ai if @options[:verbose]
      @csv << row
      @csv.flush
    end

    protected

    def _curler
      @curler ||= begin
        # curler
        options = { user_agent: "sinew/#{VERSION}" }
        options[:dir] = @options[:cache] if @options[:cache]
        options[:verbose] = false if @options[:quiet]
        Curler.new(options)
      end
    end

    def _run
      @csv = @path = nil

      file = @options[:file]
      if !File.exists?(file)
        Util.fatal("#{file} not found")
      end

      tm = Time.now
      instance_eval(File.read(file, mode: "rb"), file)
      if @path
        _banner("Finished #{@path} in #{(Time.now - tm).to_i}s.")
      else
        _banner("Finished in #{(Time.now - tm).to_i}s.")
      end
    end

    def _http(url, params, method)
      url = url.to_s
      raise "invalid url #{url.inspect}" if url !~ /^http/i

      # decode entities
      url = CODER.decode(url)

      # handle params
      body = nil
      if params
        q = params.map { |key, value| [CGI.escape(key.to_s), CGI.escape(value.to_s)] }.sort
        q = q.map { |key, value| "#{key}=#{value}" }.join("&")
        if method == :get
          separator = url.include?(??) ? "&" : "?"
          url = "#{url}#{separator}#{q}"
        else
          body = q
        end
      end

      begin
        if method == :get
          path = _curler.get(url)
        else
          path = _curler.post(url, body)
        end
        @raw = File.read(path, mode: "rb")
      rescue Curler::Error => e
        $stderr.puts "xxx #{e.message}"
        @raw = ""
      end

      # setup local variables
      @url, @uri = _curler.url, _curler.uri
      @html = nil
      @clean = nil
      @noko = nil
    end

    def _normalize(s, key = nil, options = {})
      case s
      when Nokogiri::XML::Element, Nokogiri::XML::NodeSet
        s = s.inner_html
      when Array
        s = s.map { |j| j.to_s }.join("|")
      else
        s = s.to_s
      end
      s = TextUtil.untag(s)
      s = s.convert_accented_html_entities
      s = TextUtil.unent(s)
      s = s.to_ascii if !options[:preserve_unicode_characters]
      s = s.squish
      s
    end

    def _banner(s)
      Util.banner(s) if !@options[:quiet]
    end
  end
end
