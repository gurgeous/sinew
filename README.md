[![Build Status](https://github.com/gurgeous/sinew/workflows/test/badge.svg?branch=master)](https://github.com/gurgeous/sinew/action)

## Welcome to Sinew

Sinew is a Ruby library for collecting data from web sites (scraping). Though small, this project is the culmination of years of effort based on crawling systems built at several different companies. Sinew has been used to crawl millions of websites.

## Key Features

- Robust crawling with the [Faraday](https://lostisland.github.io/faraday/) HTTP client
- Aggressive caching with [httpdisk](https://github.com/gurgeous/httpdisk/)
- Easy parsing with HTML cleanup, Nokogiri, JSON, etc.
- CSV generation for crawled data

## Installation

```ruby
# install gem
$ gem install sinew

# or add to your Gemfile:
gem 'sinew'
```

## Table of Contents

<!--- markdown-toc --no-firsth1 --maxdepth 1 readme.md -->

- [Sinew 4](#sinew-4-june-2021)
- [Quick Example](#quick-example)
- [How it Works](#how-it-works)
- [Reference](#dsreference)
- [Hints](#hints)
- [Limitations](#limitations)
- [Changelog](#changelog)
- [License](#license)

## Sinew 4 (June 2021)

**Breaking change**

We are pleased to announce the release of Sinew 4. The Sinew DSL exposes a single `sinew` method in lieu of the many methods exposed in Sinew 3. Because of this single entry point, Sinew is now much easier to embed in other applications. Also, each Sinew 4 request returns a full Response object to faciliate parallelism.

Sinew uses the [Faraday](https://lostisland.github.io/faraday/) HTTP client with the [httpdisk](https://github.com/gurgeous/httpdisk/) middleware for aggressive caching of responses.

## Quick Example

Here's an example for collecting the links from httpbingo.org. Paste this into a file called `sample.sinew` and run `sinew sample.sinew`. It will create a `sample.csv` file containing the href and text for each link:

```ruby
# get the url
response = sinew.get "https://httpbingo.org"

# use nokogiri to collect links
response.noko.css("ul li a").each do |a|
  row = { }
  row[:url] = a[:href]
  row[:title] = a.text

  # append a row to the csv
  sinew.csv_emit(row)
end
```

## How it Works

There are three main features provided by Sinew.

#### Recipes

Sinew uses recipe files to crawl web sites. Recipes have the .sinew extension, but they are plain old Ruby. Here's a trivial example that calls `get` to make an HTTP GET request:

```ruby
response = sinew.get "https://www.google.com/search?q=darwin"
response = sinew.get "https://www.google.com/search", q: "charles darwin"
```

Once you've done a `get`, you can access the document in a few different formats. In general, it's easiest to use `noko` to automatically parse and interact with HTML results. If Nokogiri isn't appropriate, fall back to regular expressions run against `body` or `html`. Use `json` if you are expecting a JSON response.

```ruby
response = sinew.get "https://www.google.com/search?q=darwin"

# pull out the links with nokogiri
links = response.noko.css("a").map { _1[:href] }
puts links.inspect

# or, use a regex
links = response.html[/<a[^>]+href="([^"]+)/, 1]
puts links.inspect
```

#### CSV Output

Recipes output CSV files. To continue the example above:

```ruby
response = sinew.get "https://www.google.com/search?q=darwin"
response.noko.css("a").each do |i|
  row = { }
  row[:href] = i[:href]
  row[:text] = i.text
  sinew.csv_emit row
end
```

Sinew creates a CSV file with the same name as the recipe, and `csv_emit(hash)` appends a row. The values of your hash are cleaned up and converted to strings:

1.  Nokogiri nodes are converted to text
1.  Arrays are joined with "|", so you can separate them later
1.  HTML tags, entities and non-ascii chars are removed
1.  Whitespace is squished

#### Caching

Sinew uses [httpdisk](https://github.com/gurgeous/httpdisk/) to aggressively cache all HTTP responses to disk in `~/.sinew`. Error responses are cached as well. Each URL will be hit exactly once, and requests are rate limited to one per second. Sinew tries to be polite.

Sinew never deletes files from the cache - that's up to you! Sinew has various command line options to refresh the cache. See `--expires`, `--force` and `--force-errors`.

Because all requests are cached, you can run Sinew repeatedly with confidence. Run it over and over again while you work on your recipe.

## Running Sinew

The `sinew` command line has many useful options. You will be using this command many times as you iterate on your recipe:

```sh
$ bin/sinew --help
Usage: sinew [options] [recipe]
    -l, --limit     quit after emitting this many rows
    --proxy         use host[:port] as HTTP proxy
    --timeout       maximum time allowed for the transfer
    -s, --silent    suppress some output
    -v, --verbose   dump emitted rows while running
From httpdisk:
    --dir           set custom cache directory
    --expires       when to expire cached requests (ex: 1h, 2d, 3w)
    --force         don't read anything from cache (but still write)
    --force-errors  don't read errors from cache (but still write)
```

`Sinew` also has many runtime options that can be set by in your recipe. For example:

```ruby
sinew.options[:headers] = { 'User-Agent' => 'xyz' }

...
```

Here is the list of available options for `Sinew`:

- **headers** - default HTTP headers to use on every request
- **ignore_params** - ignore these query params when generating httpdisk cache keys
- **insecure** - ignore SSL errors
- **params** - default query parameters to use on every request
- **rate_limit** - minimum time between network requests
- **retries** - number of times to retry each failed request
- **url_prefix** - deafult URL base to use on every request

## Reference

#### Making HTTP requests

- `sinew.get(url, params = nil, headers = nil)` - fetch a url with GET
- `sinew.post(url, body = nil, headers = nil)` - fetch a url with POST, using `form` as the URL encoded POST body.
- `sinew.post_json(url, body = nil, headers = nil)` - fetch a url with POST, using `json` as the POST body.

#### Parsing the response

Each request method returns a `Sinew::Response`. The response has several helpers to make parsing easier:

- `body` - the raw body
- `html` - like `body`, but with a handful of HTML-specific whitespace cleanups
- `noko` - parse as HTML and return a [Nokogiri](http://nokogiri.org) document
- `xml` - parse as XML and return a [Nokogiri](http://nokogiri.org) document
- `json` - parse as JSON, with symbolized keys
- `mash` - parse as JSON and return a [Hashie::Mash](https://github.com/hashie/hashie#mash)
- `url` - the url of the request. If the request goes through a redirect, `url` will reflect the final url.

#### Writing CSV

- `sinew.csv_header(columns)` - specify the columns for CSV output. If you don't call this, Sinew will use the keys from the first call to `sinew.csv_emit`.
- `sinew.csv_emit(hash)` - append a row to the CSV file

#### Advanced: Cache

Sinew has some advanced helpers for checking the httpdisk cache. For the following methods, `body` hashes default to form body type.

- `sinew.cached?(method, url, params = nil, body = nil)` - check if request is cached
- `sinew.uncache(method, url, params = nil, body = nil)` - remove cache file, if any
- `sinew.status(method, url, params = nil, body = nil)` - get httpdisk status

Plus some caching helpers in Sinew::Response:

- `diskpath` - the location on disk for the cached httpdisk response
- `uncache` - remove cache file for this response

## Hints

Writing Sinew recipes is fun and easy. The builtin caching means you can iterate quickly, since you won't have to re-fetch the data. Here are some hints for writing idiomatic recipes:

- Sinew doesn't (yet) check robots.txt - please check it manually.
- Prefer Nokogiri over regular expressions wherever possible. Learn [CSS selectors](http://www.w3schools.com/cssref/css_selectors.asp).
- In Chrome, `$` in the console is your friend.
- Fallback to regular expressions if you're desperate. Depending on the site, use either `body` or `html`. `html` is probably your best bet. `body` is good for crawling Javascript, but it's fragile if the site changes.
- Learn to love `String#[regexp]`, which is an obscure operator but incredibly handy for Sinew.
- Laziness is useful. Keep your CSS selectors and regular expressions simple, so maybe they'll work again the next time you need to crawl a site.
- Don't be afraid to mix CSS selectors, regular expressions, and Ruby:

```ruby
noko.css("table")[4].css("td").select do
  _1[:width].to_i > 80
end.map(&:text)
```

- Debug your recipes using plain old `puts`, or better yet use `ap` from [amazing_print](https://github.com/amazing-print/amazing_print).
- Run `sinew -v` to get a report on every `csv_emit`. Very handy.
- Add the CSV files to your git repo. That way you can version them and get diffs!

## Limitations

- Caching is based on URL, so use caution with cookies and other forms of authentication
- Almost no support for international (non-english) characters

## Changelog

#### 4.0.0 (unreleased)

- Rewritten to use simpler DSL
- Upgraded to httpdisk 0.5 to take advantage of the new encoding support

#### 3.0.0 (May 2021)

- Major rewrite of network and caching layer. See above.
- Use Faraday HTTP client with sinew middleware for caching.
- Supports multiple proxies (`--proxy host1,host2,...`)

#### 2.0.4 (May 2018)

- Handle and cache more errors (too many redirects, connection failures, etc.)
- Support for adding uri.scheme in generate_cache_key
- Added status `code`, a peer to `uri`, `raw`, etc.

#### 2.0.3 (May 2018)

- &amp; now normalizes to & (not and)

#### 2.0.2 (May 2018)

- Support for `--limit`, `--proxy` and the `xml` variable
- Dedup - warn and ignore if row[:url] has already been emitted
- Auto gunzip if contents are compressed

#### 2.0.1 (May 2018)

- Support for legacy cached `head` files from Sinew 1

#### 2.0.0 (May 2018)

- Complete rewrite. See above.

#### 1.0.3 (June 2012)

...

## License

This extension is [licensed under the MIT License](LICENSE).
