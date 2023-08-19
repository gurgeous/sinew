require_relative "lib/sinew"

sinew = Sinew.new(output: "sample.csv", verbose: true)

response = sinew.get "http://httpbingo.org"
response.noko.css("ul li a").each do |a|
  row = {}
  row[:url] = a[:href]
  row[:title] = a.text
  sinew.csv_emit(row)
end

sinew.get "http://httpbingo.org/redirect/2"
