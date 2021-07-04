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
    sinew = sinew(expires: 123)
    2.times { sinew.get('http://host') }
    path = Dir[File.join(@tmpdir, 'host', '*', '*')]
    FileUtils.touch(path, mtime: Time.now - 999)
    sinew.get('http://host') # stale
    assert_requested :get, 'host', times: 2
  end

  def test_options_force
    sinew = sinew(force: true)
    2.times { sinew.get('http://host') }
    assert_requested :get, 'host', times: 2
  end

  def test_options_ignore_params
    sinew = sinew(ignore_params: %w[b])
    sinew.get('http://host?b=1')
    sinew.get('http://host?b=2')
    assert_requested :get, 'host/?b=1', times: 1
    assert_requested :get, 'host/?b=2', times: 0
  end

  def test_options_default_request
    sinew = sinew(params: { a: 1 }, headers: { b: '2' }, url_prefix: 'http://host')
    sinew.get('hello')
    assert_requested :get, 'host/hello?a=1', headers: { b: '2' }
  end

  def test_options_proxy
    http = Net::HTTP.new('host')
    Net::HTTP.stubs(:new).returns(http).with('host', 80, 'boom', 123, nil, nil)
    sinew(proxy: 'boom:123').get('http://host')
    assert_requested(:get, 'host', times: 1)
  end

  def test_options_rate_limit
    # don't sleep, but expect it to get called
    Faraday::RateLimiter.any_instance.expects(:sleep)
    sinew = sinew(rate_limit: 1)
    sinew.get('http://host?a=1')
    sinew.get('http://host?a=2')
  end

  def test_options_retries
    stub_request(:get, 'error').to_return(status: 500)
    sinew(retries: 4).get('http://error')
    assert_requested(:get, 'error', times: 5)
  end

  #
  # requests & csv
  #

  def test_get
    sinew.get('http://host', { a: 1 }, { b: '2' })
    assert_requested :get, 'host?a=1', headers: { b: '2' }
  end

  def test_post
    sinew.post('http://host', { a: 1 }, { b: '2' })
    assert_requested :post, 'host', body: 'a=1', headers: { b: '2' }
  end

  def test_post_json
    sinew.post_json('http://host', { a: 1 }, { b: '2' })
    assert_requested :post, 'host', body: '{"a":1}', headers: { b: '2', 'Content-Type': 'application/json' }
  end

  #
  # httpdisk
  #

  def test_status
    sinew = self.sinew(params: { a: 1 })

    # we'll test these in a sec
    sinew.get('http://host/get?b=2', c: 3)
    sinew.post('http://host/post_string?b=2', 'string')
    sinew.post('http://host/post_form?b=2', { form: 'form' })
    sinew.post_json('http://host/post_json?b=2', { json: 'json' })

    # miss
    assert !sinew.cached?('get', 'http://host/blah')

    # hits
    assert sinew.cached?('get', 'http://host/get?b=2', c: 3)
    assert sinew.cached?('post', 'http://host/post_string?b=2', nil, 'string')
    assert sinew.cached?('post', 'http://host/post_form?b=2', nil, { form: 'form' })
    assert sinew.cached?('post', 'http://host/post_json?b=2', nil, { json: 'json' }.to_json)
  end

  def test_uncache
    sinew, url = self.sinew, 'http://host/blah'

    assert !sinew.cached?('get', url) # miss
    sinew.get(url)
    assert sinew.cached?('get', url) # hit
    sinew.uncache('get', url)
    assert !sinew.cached?('get', url) # back to miss
  end

  #
  # csv
  #

  def test_csv
    sinew = self.sinew
    sinew.csv_header(:a, :b)
    sinew.csv_emit(a: 1)
    assert_equal("a,b\n1,\n", IO.read(sinew.csv.path))
  end

  protected

  def sinew(args = {})
    args[:dir] = @tmpdir if !args.key?(:dir)
    args[:silent] = true if !args.key?(:silent)
    args[:output] = "#{@tmpdir}/output.csv"
    Sinew.new(args)
  end
end
