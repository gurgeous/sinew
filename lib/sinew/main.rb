require "nokogiri" # must be loaded before awesome_print
require "awesome_print"
require "htmlentities"
require "stringex"

# modify NodeSet to join with SPACE instead of empty string
class Nokogiri::XML::NodeSet
  alias :old_inner_html :inner_html
  alias :old_inner_text :inner_text  
  
  def inner_text
    collect { |i| i.inner_text }.join(" ")
  end
  def inner_html *args
    collect { |i| i.inner_html(*args) }.join(" ")
  end
end

# text_just_me
class Nokogiri::XML::Node
  def text_just_me
    t = children.find { |i| i.node_type == Nokogiri::XML::Node::TEXT_NODE }
    t && t.text
  end
end
class Nokogiri::XML::NodeSet
  def text_just_me
    map { |i| i.text_just_me }.join(" ")
  end
end

module Sinew
  class Main
    CODER = HTMLEntities.new
    CURLER = Curler.new

    attr_accessor :url, :uri, :raw

    def initialize(options)
      @options = options.dup
      @csv = @path = nil

      file = @options[:file]
      if !File.exists?(file)
        Util.fatal("#{file} not found")
      end

      tm = Time.now
      instance_eval(File.read(file), file)
      if @path
        Util.banner("Finished #{@path} in #{(Time.now - tm).to_i}s.")
      else
        Util.banner("Finished in #{(Time.now - tm).to_i}s.")
      end
    end

    def get(url, params = nil)
      http(url, params, :get)
    end
    
    def post(url, params = nil)
      http(url, params, :post)
    end

    def http(url, params, method)
      url = url.to_s
      raise "invalid url #{url.inspect}" if url !~ /^http/i

      # decode entities
      url = CODER.decode(url)

      # handle params
      body = nil
      if params
        q = params.map { |key, value| [Sinew.h_maybe(key), Sinew.h_maybe(value)] }.sort
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
          path = CURLER.get(url)
        else
          path = CURLER.post(url, body)
        end
        @raw = File.read(path)
      rescue Curler::Error => e
        $stderr.puts "xxx #{e.message}"
        @raw = ""
      end

      @url, @uri = CURLER.url, CURLER.uri
      @html = nil
      @clean = nil
      @noko = nil

      nil
    end
    
    #
    # lazy accessors for cleaned up version
    #

    def html
      if !@html
        @html = TextUtil.html_tidy(@raw)
        nelements = @raw.count("<")
        if nelements > 1
          # is there a problem with tidy?
          percent = 100 * @html.count("<") / nelements
          if percent < 80
            # bad xml processing instruction? Try fixing it.
            maybe = TextUtil.html_tidy(@raw.gsub(/<\?[^>]*?>/, ""))
            new_percent = 100 * maybe.count("<") / nelements
            if new_percent > 80
              # yes!
              @html = maybe
            else
              Util.warning "Hm - it looks like tidy ate some of your file (#{percent}%)" if percent < 90
            end
          end
        end
      end
      @html
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
      @csv = FasterCSV.open(file, "w")
      @csv_keys = args
      @csv << @csv_keys
      Util.banner("Writing to #{@path}...")
    end

    def normalize(key, s)
      case s
      when Nokogiri::XML::Element, Nokogiri::XML::NodeSet
        s = s.inner_html
      when Array
        s = s.map { |j| j.to_s }.join("|")
      else
        s = s.to_s
      end
      s = s.untag.convert_accented_entities.unent.to_ascii.squish
      s
    end

    def csv_emit(row, options = {})
      csv_header(row.keys.sort) if !@csv

      print = { }
      row = @csv_keys.map do |i|
        s = normalize(i, row[i])
        print[i] = s if !s.empty?
        s
      end
      $stderr.puts print.ai if @options[:verbose]
      @csv << row    
      @csv.flush
    end

    protected

    #
    # helpers
    #

    def self.h(s)
      CGI.escape(s.to_s)
    end

    def self.h_maybe(s)
      s = s.to_s
      s = h(s) if (s !~ /%([A-Za-z0-9]{2})/) && !s.include?("+")
      s
    end
  end
end
