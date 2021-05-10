require_relative 'test_helper'

class TestRecipe < MiniTest::Test
  DIR = File.expand_path('recipes', __dir__)
  TEST_SINEW = "#{TMP}/test.sinew".freeze
  TEST_CSV = "#{TMP}/test.csv".freeze

  def test_recipes
    Dir.chdir(DIR) do
      Dir['*.sinew'].sort.each do |filename|
        recipe = IO.read(filename)

        # get ready
        IO.write(TEST_SINEW, recipe)
        sinew = Sinew::Main.new(cache: TMP, quiet: true, recipe: TEST_SINEW)

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
        csv = IO.read(TEST_CSV)
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
