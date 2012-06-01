## Welcome to Sinew

Sinew collects structured data from web sites (screen scraping). It comes with a robust caching system, integration with nokogiri, and a DSL that makes crawling easy.

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
  
  # emit a row to the csv
  csv_emit(row)
end
```

If you paste this into a file called `bestsellers.sinew` and run `sinew bestsellers.sinew`, it will create a `bestsellers.csv` file containing the url, title and img for each book.

## Full Documentation

Full docs are in the wiki:

https://github.com/gurgeous/sinew/wiki
