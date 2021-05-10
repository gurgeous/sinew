require 'csv'
require 'set'
require 'sterile'

#
# CSV output.
#

module Sinew
  class Output
    attr_reader :sinew, :columns, :rows, :urls, :csv

    def initialize(sinew)
      @sinew = sinew
      @rows = []
      @urls = Set.new
    end

    def filename
      @filename ||= begin
        recipe = sinew.options[:recipe]
        ext = File.extname(recipe)
        if ext.empty?
          "#{recipe}.csv"
        else
          recipe.gsub(ext, '.csv')
        end
      end
    end

    def header(columns)
      sinew.banner("Writing to #{filename}...") if !sinew.quiet?

      columns = columns.flatten
      @columns = columns

      # open csv, write header row
      @csv = CSV.open(filename, 'wb')
      csv << columns
    end

    def emit(row)
      # implicit header if necessary
      header(row.keys) if !csv

      # don't allow duplicate urls
      return if dup_url?(row)

      rows << row.dup

      # map columns to row, and normalize along the way
      print = {}
      row = columns.map do |i|
        value = normalize(row[i])
        print[i] = value if value.present?
        value
      end

      # print
      sinew.vputs print.ai

      csv << row
      csv.flush
    end

    def count
      rows.length
    end

    def report
      return if count == 0

      sinew.banner("Got #{count} rows.")

      # calculate counts
      counts = Hash.new(0)
      rows.each do |row|
        row.each_pair { |k, v| counts[k] += 1 if v.present? }
      end
      # sort by counts
      cols = columns.sort_by { |i| [ -counts[i], i ] }

      # report
      len = cols.map { |i| i.to_s.length }.max
      fmt = "  %-#{len + 1}s %7d / %-7d %6.1f%%\n"
      cols.each do |col|
        $stderr.printf(fmt, col, counts[col], count, counts[col] * 100.0 / count)
      end
    end

    def normalize(s)
      # noko/array/misc => string
      s = case s
      when Nokogiri::XML::Element, Nokogiri::XML::NodeSet
        s.inner_html
      when Array
        s.map(&:to_s).join('|')
      else
        s.to_s
      end

      # strip html tags. Note that we replace tags with spaces
      s = s.gsub(/<[^>]+>/, ' ')

      # Converts MS Word 'smart punctuation' to ASCII
      s = Sterile.plain_format(s)

      # &aacute; &amp; etc.
      s = Sterile.decode_entities(s)

      # "šţɽĩɳģ" => "string"
      s = Sterile.transliterate(s)

      # squish
      s = s.squish

      s
    end
    protected :normalize

    def dup_url?(row)
      if url = row[:url]
        if urls.include?(url)
          sinew.warning("duplicate url: #{url}") if !sinew.quiet?
          return true
        end
        urls << url
      end
      false
    end
    protected :dup_url?
  end
end
