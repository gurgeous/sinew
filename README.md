## Welcome to Sinew

Sinew collects structured data from web sites (screen scraping). It comes with a DSL that makes crawling easy, a robust caching system, and integration with nokogiri.

Though small, this project is the culmination of years of effort based on indexing systems built at several different companies.

## Example

Here's an example for collecting Amazon's bestseller list:

```ruby
# get the url
get "http://www.amazon.com/gp/bestsellers/books/ref=sv_b_3"

# use nokogiri to find books
noko.css(".zg_itemRow").each do |item|
  # pull out the stuff we care about using nokogiri
  row = { }
  row[:url] = item.css(".zg_title a").first[:href]
  row[:title] = item.css(".zg_title")
  row[:img] = item.css(".zg_itemImage_normal img").first[:src]
  
  # append a row to the csv
  csv_emit(row)
end
```

If you paste this into a file called `bestsellers.sinew` and run `sinew bestsellers.sinew`, it will create a `bestsellers.csv` file containing the url, title and img for each bestseller.

## Full Documentation

Full docs are in the wiki:

https://github.com/gurgeous/sinew/wiki
