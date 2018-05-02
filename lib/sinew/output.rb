require 'csv'
require 'stringex'

#
# CSV output.
#

module Sinew
  class Output
    attr_reader :sinew, :columns, :rows, :csv

    def initialize(sinew)
      @sinew = sinew
      @rows = []
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

      #
      # Below uses stringex
      #
      # github.com/rsl/stringex/blob/master/lib/stringex/string_extensions.rb
      # github.com/rsl/stringex/blob/master/lib/stringex/localization/conversion_expressions.rb
      #

      # <a>b</a> => b
      s = s.strip_html_tags

      # Converts MS Word 'smart punctuation' to ASCII
      s = s.convert_smart_punctuation

      # "&aacute;".convert_accented_html_entities # => "a"
      s = s.convert_accented_html_entities

      # &amp, &frac, etc.
      s = s.convert_miscellaneous_html_entities

      # convert unicode => regular characters
      s = s.to_ascii

      # squish
      s = s.squish

      s
    end
    protected :normalize
  end
end
