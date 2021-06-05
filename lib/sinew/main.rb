module Sinew
  class Main
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def recipe
      @recipe ||= load_recipe
    end

    def run
      tm = Time.now
      recipe.sinew_header if !options[:silent]
      begin
        recipe.run
      rescue LimitError
        # ignore - this is flow control for --limit
      end
      recipe.sinew_footer(Time.now - tm) if !options[:silent]
    end

    protected

    # Low level helper for instantiating the recipe. We ask Sinew::Base for the
    # most recently defined subclass. This can fail in certain edge cases (dup
    # or multiple subclasses) but should be perfect for running sinew xxx.rb.
    def load_recipe
      # load file
      require(File.expand_path(options[:recipe]))

      # instantiate
      klass = Sinew::Base.subclasses.last
      raise "no Sinew::Base subclass found in #{options[:recipe].inspect}" if !klass

      klass.new(options)
    end
  end
end
