require_relative 'test_helper'

class TestRecipes < MiniTest::Test
  def test_recipes
    Dir.chdir(File.join(__dir__, 'recipes')) do
      Dir['*.sinew'].sort.each do |path|
        # run
        actual = File.join(@tmpdir, 'test.csv')
        main = Sinew::Main.new(dir: @tmpdir, silent: true, recipe: path, output: actual)
        main.run

        # check
        expected = output_from(path)
        actual = IO.read(actual)
        assert_equal expected, actual, "output didn't match for test/recipes/#{path}"
      end
    end
  end

  protected

  def output_from(path)
    lines = IO.read(path).split("\n")
    first_line = lines.index { _1 =~ /^# OUTPUT/ }
    raise "# OUTPUT not found in test/recipes/#{path}" if !first_line

    output = lines[first_line + 1..]
    output = output.map { _1.gsub(/^# /, '') }
    output = output.join("\n")
    output += "\n"
    output
  end
end
