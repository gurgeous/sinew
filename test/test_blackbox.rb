require 'test_helper'

class TestBlackbox < MiniTest::Test
  def test_blackbox
    # --help (fast)
    output = `bin/sinew --help`
    assert $CHILD_STATUS.success?
    assert_match(/From httpdisk/i, output)

    # real simple end-to-end test, no network required
    blackbox = "#{@tmpdir}/blackbox.rb"
    IO.write(blackbox, <<~EOF)
      class Blackbox < Sinew::Base
        def run
          csv_emit(a: 1)
        end
      end
    EOF

    output = `bin/sinew #{blackbox}`
    assert $CHILD_STATUS.success?
    assert_match(/Done/i, output)
  end
end
