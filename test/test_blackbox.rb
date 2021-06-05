require 'test_helper'

class TestBlackbox < MiniTest::Test
  def test_blackbox
    # --help (fast)
    output = `bin/sinew --help`
    assert $CHILD_STATUS.success?
    assert_match(/From httpdisk/i, output)

    # real simple end-to-end test, no network required
    recipe = recipe('csv_emit(a: 1)')
    output = `bin/sinew #{recipe}`
    assert $CHILD_STATUS.success?
    assert_match(/Done/i, output)
  end
end
