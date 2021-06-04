require_relative 'test_helper'

class TestRecipe < MiniTest::Test
  DIR = File.expand_path('recipes', __dir__)

  def test_recipes
    test_sinew = "#{@tmpdir}/test.sinew".freeze
    test_csv = "#{@tmpdir}/test.csv".freeze

    Dir.chdir(DIR) do
      Dir['*.sinew'].sort.each do |filename|
        recipe = IO.read(filename)

        # get ready
        IO.write(test_sinew, recipe)
        sinew = Sinew::Main.new(dir: @tmpdir, quiet: true, recipe: test_sinew)

        # read OPTIONS
        if options = options_from(recipe)
          options.each do |key, value|
            sinew.options[key] = value
          end
        end

        # read OUTPUT
        output = output_from(recipe, filename)

        # run
        sinew.run

        # assert
        csv = IO.read(test_csv)
        assert_equal(output, csv, "Output didn't match for recipes/#{filename}")
      end
    end
  end

  def options_from(recipe)
    if options = recipe[/^#\s*OPTIONS\s*(\{.*\})/, 1]
      # rubocop:disable Security/Eval
      eval(options)
      # rubocop:enable Security/Eval
    end
  end
  protected :options_from

  def output_from(recipe, filename)
    lines = recipe.split("\n")
    first_line = lines.index { |i| i =~ /^# OUTPUT/ }
    if !first_line
      raise "# OUTPUT not found in recipes/#{filename}"
    end

    output = lines[first_line + 1..]
    output = output.map { |i| i.gsub(/^# /, '') }
    output = output.join("\n")
    output += "\n"
    output
  end
  protected :output_from
end
