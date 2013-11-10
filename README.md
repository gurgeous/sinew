## Welcome to Sinew

Sinew collects structured data from web sites (screen scraping). It provides a Ruby DSL built for crawling, a robust caching system, and integration with [Nokogiri](http://nokogiri.org). Though small, this project is the culmination of years of effort based on crawling systems built at several different companies.

Sinew requires Ruby 1.9, [HTML Tidy](http://tidy.sourceforge.net) and [Curl](http://curl.haxx.se).

Sinew is distributed as a ruby gem:

```ruby
gem install sinew
```

## Example

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

## How does Sinew differ from Mechanize?

I'm not an expert on Mechanize, but this question has come up repeatedly and I'll try to address it. Mechanize is a great toolkit and it's better for some situations. Briefly:

* Sinew caches all HTTP requests on disk. That makes it possible to iterate quickly. Crawl once and then continue to work on your recipe. Run the recipe over and over while you tune your CSS selectors and regular expressions.
* Sinew runs responses through [HTML Tidy](http://tidy.sourceforge.net). This cleans up dirty HTML and makes it easier to parse in many cases, especially if you have to fallback to regular expressions instead of Nokogiri. Unfortunately, this is a common use case in my experience.
* Sinew outputs CSV files. It does exactly one thing and it does it well - Sinew crawls a site and outputs a CSV file. Mechanize is a more general toolkit.

## Full Documentation

Full docs are in the wiki:

https://github.com/gurgeous/sinew/wiki
