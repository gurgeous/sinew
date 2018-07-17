![Travis](https://travis-ci.org/gurgeous/sinew.svg?branch=master)

## Welcome to Sinew

Sinew collects structured data from web sites (screen scraping). It provides a Ruby DSL built for crawling, a robust caching system, and integration with [Nokogiri](http://nokogiri.org). Though small, this project is the culmination of years of effort based on crawling systems built at several different companies.

Sinew is distributed as a ruby gem:

```sh
$ gem install sinew
```

or in your Gemfile:

```ruby
gem 'sinew'
```

## Table of Contents

<!--- markdown-toc --no-firsth1 --maxdepth 1 readme.md -->

- [Sinew 2](#sinew-2-may-2018)
- [Quick Example](#quick-example)
- [How it Works](#how-it-works)
- [DSL Reference](#dsl-reference)
- [Hints](#hints)
- [Limitations](#limitations)
- [Changelog](#changelog)
- [License](#license)

## Sinew 2 (May 2018)

I am pleased to announce the release of Sinew 2.0, a complete rewrite of Sinew for the modern era. Enhancements include:

- Remove dependencies on active_support, curl and tidy. We use HTTParty now.
- Much easier to customize requests in `.sinew` files. For example, setting User-Agent or Bearer tokens.
- More operations like `post_json` or the generic `http`. These methods are thin wrappers around HTTParty.
- New end-of-run report.
- Tests, rubocop, vscode settings, travis, etc.

**Breaking change**

Sinew uses a new format for cached responses. Old Sinew 1 cache directories must be removed before running Sinew again. Sinew 2 might choke on Sinew 1 cache directores when reading `head/`. This is not tested or supported.

## Quick Example

Here's an example for collecting the links from httpbin.org:

```ruby
# get the url
get "http://httpbin.org"

# use nokogiri to collect links
noko.css("ul li a").each do |a|
  row = { }
  row[:url] = a[:href]
  row[:title] = a.text

  # append a row to the csv
  csv_emit(row)
end
```

If you paste this into a file called `sample.sinew` and run `sinew sample.sinew`, it will create a `sample.csv` file containing the href and text for each link.

## How it Works

There are three main features provided by Sinew.

#### The Sinew DSL

Sinew uses recipe files to crawl web sites. Recipes have the `.sinew` extension, but they are plain old Ruby. The [Sinew DSL](#dsl) makes crawling easy. Use `get` to make an HTTP GET:

```ruby
get "https://www.google.com/search?q=darwin"
get "https://www.google.com/search", q: "charles darwin"
```

Once you've done a `get`, you have access to the document in a few different formats. In general, it's easiest to use `noko` to automatically parse and interact with the results. If Nokogiri isn't appropriate, you can fall back to regular expressions run against `raw` or `html`. Use `json` if you are expecting a JSON response.

```ruby
get "https://www.google.com/search?q=darwin"

# pull out the links with nokogiri
links = noko.css("a").map { |i| i[:href] }
puts links.inspect

# or, use a regex
links = html[/<a[^>]+href="([^"]+)/, 1]
puts links.inspect
```

#### CSV Output

Recipes output CSV files. To continue the example above:

```ruby
get "https://www.google.com/search?q=darwin"
noko.css("a").each do |i|
  row = { }
  row[:href] = i[:href]
  row[:text] = i.text
  csv_emit row
end
```

Sinew creates a CSV file with the same name as the recipe, and `csv_emit(hash)` appends a row. The values of your hash are converted to strings:

1.  Nokogiri nodes are converted to text
1.  Arrays are joined with "|", so you can separate them later
1.  HTML tags, entities and non-ascii chars are removed
1.  Whitespace is squished

#### Caching

Requests are made using HTTParty, and all responses are cached on disk in `~/.sinew`. Error responses are cached as well. Each URL will be hit exactly once, and requests are rate limited to one per second. Sinew tries to be polite.

The files in `~/.sinew` have nice names and are designed to be human readable. This helps when writing recipes. Sinew never deletes files from the cache - that's up to you!

Because all requests are cached, you can run Sinew repeatedly with confidence. Run it over and over again while you build up your recipe.

## DSL Reference

#### Making requests

- `get(url, query = {})` - fetch a url with HTTP GET. URL parameters can be added using `query.
- `post(url, form = {})` - fetch a url with HTTP POST, using `form` as the URL encoded POST body.
- `post_json(url, json = {})` - fetch a url with HTTP POST, using `json` as the POST body.
- `http(method, url, options = {})` - use this for more complex requests

#### Parsing the response

These variables are set after each HTTP request.

- `raw` - the raw response from the last request
- `html` - like `raw`, but with a handful of HTML-specific whitespace cleanups
- `noko` - parse the response as HTML and return a [Nokogiri](http://nokogiri.org) document
- `xml` - parse the response as XML and return a [Nokogiri](http://nokogiri.org) document
- `json` - parse the response as JSON, with symbolized keys
- `url` - the url of the last request. If the request goes through a redirect, `url` will reflect the final url.
- `uri` - the URI of the last request. This is useful for resolving relative URLs.

#### Writing CSV

- `csv_header(keys)` - specify the columns for CSV output. If you don't call this, Sinew will use the keys from the first call to `csv_emit`.
- `csv_emit(hash)` - append a row to the CSV file

## Hints

Writing Sinew recipes is fun and easy. The builtin caching means you can iterate quickly, since you won't have to re-fetch the data. Here are some hints for writing idiomatic recipes:

- Sinew doesn't (yet) check robots.txt - please check it manually.
- Prefer Nokogiri over regular expressions wherever possible. Learn [CSS selectors](http://www.w3schools.com/cssref/css_selectors.asp).
- In Chrome, `$` in the console is your friend.
- Fallback to regular expressions if you're desperate. Depending on the site, use either `raw` or `html`. `html` is probably your best bet. `raw` is good for crawling Javascript, but it's fragile if the site changes.
- Learn to love `String#[regexp]`, which is an obscure operator but incredibly handy for Sinew.
- Laziness is useful. Keep your CSS selectors and regular expressions simple, so maybe they'll work again the next time you need to crawl a site.
- Don't be afraid to mix CSS selectors, regular expressions, and Ruby:

```ruby
noko.css("table")[4].css("td").select { |i| i[:width].to_i > 80 }.map(&:text)
```

- Debug your recipes using plain old `puts`, or better yet use `ap` from [awesome_print](https://github.com/michaeldv/awesome_print).
- Run `sinew -v` to get a report on every `csv_emit`. Very handy.
- Add the CSV files to your git repo. That way you can version them and get diffs!

## Limitations

- Caching is based on URL, so use caution with cookies and other forms of authentication
- Almost no support for international (non-english) characters

## Changelog

#### 2.0.5 (unreleased)

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
