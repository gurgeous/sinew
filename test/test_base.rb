require 'test_helper'

class TestBase < MiniTest::Test
  def setup
    super
    stub_request(:any, /host/)
  end

  #
  # options. not all, but important ones that are not in test_args
  #

  def test_options_expires
    base = base(expires: 123)
    2.times { base.get('http://host') }
    path = Dir["#{File.join(@tmpdir, 'host')}/*/*"]
    FileUtils.touch(path, mtime: Time.now - 999)
    base.get('http://host') # stale
    assert_requested :get, 'host', times: 2
  end

  def test_options_force
    base = base(force: true)
    2.times { base.get('http://host') }
    assert_requested :get, 'host', times: 2
  end

  def test_options_ignore_params
    base = base(ignore_params: %w[b])
    base.get('http://host?b=1')
    base.get('http://host?b=2')
    assert_requested :get, 'host/?b=1', times: 1
    assert_requested :get, 'host/?b=2', times: 0
  end

  def test_options_default_request
    base = base(headers: { a: '1' }, params: { b: 2 }, url_prefix: 'http://host')
    base.get('hello')
    assert_requested :get, 'host/hello?b=2', headers: { a: '1' }
  end

  def test_options_proxy
    http = Net::HTTP.new('host')
    Net::HTTP.stubs(:new).returns(http).with('host', 80, 'boom', 123, nil, nil)
    base(proxy: 'boom:123').get("http://host")
    assert_requested(:get, 'host', times: 1)
  end

  def test_options_rate_limit
    # don't sleep, but expect it to get called
    Faraday::RateLimiter.any_instance.expects(:sleep)
    base = base(rate_limit: 1)
    base.get('http://host?a=1')
    base.get('http://host?a=2')
  end

  def test_options_retries
    stub_request(:get, 'error').to_return(status: 500)
    base(retries: 4).get('http://error')
    assert_requested(:get, 'error', times: 5)
  end

  #
  # requests & csv
  #

  def test_get
    base.get('http://host', { a: 1 }, { b: '2' })
    assert_requested :get, 'host?a=1', headers: { b: '2' }
  end

  def test_post
    base.post('http://host', { a: 1 }, { b: '2' })
    assert_requested :post, 'host', body: "a=1", headers: { b: '2' }
  end

  def test_post_json
    base.post_json('http://host', { a: 1 }, { b: '2' })
    assert_requested :post, 'host', body: '{"a":1}', headers: { b: '2', 'Content-Type': 'application/json' }
  end

  def test_csv
    load recipe("csv_header(:a, :b) ; csv_emit(a: 1)")
    recipe = Recipe.new
    recipe.run
    assert_equal("a,b\n1,\n", IO.read(recipe.sinew_csv.path))
  end

  protected

  def base(args = {})
    args[:dir] = @tmpdir if !args.key?(:dir)
    args[:silent] = true if !args.key?(:silent)
    Sinew::Base.new(args)
  end
end
