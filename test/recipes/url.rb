class Url < Sinew::Base
  def run
    # This tests get by URI, URI math, and csv_emit with url
    response = get(URI.parse('http://httpbingo.org/html'))
    csv_emit(url: response.url)

    response = get(response.url + '/get')
    csv_emit(url: response.url)
  end
end

# OUTPUT
# url
# http://httpbingo.org/html
# http://httpbingo.org/get
