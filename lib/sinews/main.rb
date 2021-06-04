module Sinews
  class Main
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      tm = Time.now

      recipe = load_recipe
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
      raise CliError, "#{path.inspect} file not found" if !File.exist?(path)

      # load file
      require(File.expand_path(path))
      klass = IO.read(path)[/class ([A-Z][A-Za-z0-9_]*)\s*<\s*Sinew/, 1]
      raise CliError, "could not find a Sinew subclass in #{path.inspect}" if !klass

      # instantiate
      Object.const_get(klass).new(options)
    end
  end
end
