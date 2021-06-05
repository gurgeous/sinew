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

    # low level helper for instantiating the recipe
    def load_recipe
      # does it exist?
      path = options[:recipe]

      # load file
      require(File.expand_path(path))
      klass = IO.read(path)[/class ([A-Z][A-Za-z0-9_]*)\s*<\s*Sinew::Base/, 1]
      raise "could not find a Sinew::Base subclass in #{path.inspect}" if !klass

      # instantiate
      Object.const_get(klass).new(options)
    end
  end
end
