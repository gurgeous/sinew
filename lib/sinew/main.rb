module Sinew
  # Helper class used by sinew bin. This exists as an independent class solely
  # for testing, otherwise it would be built into the bin script.
  class Main
    attr_reader :sinew

    def initialize(options)
      options[:output] ||= begin
        src = options[:recipe]
        dst = File.join(File.dirname(src), "#{File.basename(src, File.extname(src))}.csv")
        dst = dst.sub(%r{^./}, '') # nice to clean this up
        dst
      end

      @sinew = Sinew.new(options)
    end

    def run
      tm = Time.now
      header if !sinew.options[:silent]
      recipe = sinew.options[:recipe]
      dsl = DSL.new(sinew)
      begin
        dsl.instance_eval(File.read(recipe, mode: 'rb'), recipe)
      rescue LimitError
        # ignore - this is flow control for --limit
      end
      footer(Time.now - tm) if !sinew.options[:silent]
    end

    protected

    #
    # header/footer
    #

    def header
      sinew.banner("Writing to #{sinew.csv.path}...")
    end

    def footer(elapsed)
      csv = sinew.csv
      count = csv.count

      if count == 0
        sinew.banner(format('Done in %ds. Nothing written.', elapsed))
        return
      end

      # summary
      msg = format('Done in %ds. Wrote %d rows to %s. Summary:', elapsed, count, csv.path)
      sinew.banner(msg)

      # tally
      tally = csv.tally.sort_by { [-_2, _1.to_s] }.to_h
      len = tally.keys.map { _1.to_s.length }.max
      fmt = "  %-#{len + 1}s %7d/%-7d %5.1f%%\n"
      tally.each do
        printf(fmt, _1, _2, count, _2 * 100.0 / count)
      end
    end

    # simple DSL for .sinew files
    class DSL
      attr_reader :sinew

      def initialize(sinew)
        @sinew = sinew
      end
    end
  end
end
