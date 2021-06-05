require 'csv'
require 'sterile'

module Sinew
  class CSV
    attr_reader :columns, :count, :csv, :path, :tally

    def initialize(path)
      @count = 0
      @path = path
    end

    # start writing
    def start(columns)
      raise 'started twice' if started?

      @columns = columns
      @tally = columns.map { [_1, 0] }.to_h
      @csv = ::CSV.open(path, 'wb').tap do
        _1 << columns
      end
    end

    def started?
      @csv != nil
    end

    # append
    def emit(row)
      # convert row to cols, and construct print (our return value)
      print = {}
      row = columns.map do
        value = normalize(row[_1])
        if value
          print[_1] = value
          tally[_1] += 1
        end
        value
      end
      @count += 1

      # emit
      csv << row
      csv.flush

      # return in case someone wants to pretty print this
      print
    end

    ASCII_ONLY = begin
      chars = (33..126).map(&:chr) - ['&']
      /\A[#{Regexp.escape(chars.join)}\s]+\Z/
    end.freeze

    def normalize(s)
      # nokogiri/array/misc => string
      s = if s.respond_to?(:inner_html)
        s.inner_html
      elsif s.is_a?(Array)
        s.join('|')
      else
        s.to_s
      end
      return if s.empty?

      # simple attempt to strip tags. Note that we replace tags with spaces
      s = s.gsub(/<[^>]+>/, ' ')

      if s !~ ASCII_ONLY
        # Converts MS Word 'smart punctuation' to ASCII
        s = Sterile.plain_format(s)

        # &aacute; &amp; etc.
        s = Sterile.decode_entities(s)

        # "šţɽĩɳģ" => "string"
        s = Sterile.transliterate(s)
      end

      # squish
      s = s.strip.gsub(/\s+/, ' ')
      return if s.empty?

      s
    end
  end
end
