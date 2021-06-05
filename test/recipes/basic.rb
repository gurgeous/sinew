class Basic < Sinew::Base
  def run
    response = get 'http://httpbingo.org/html'
    response.body.scan(/<h1>([^<]+)/) do
      csv_emit(h1: Regexp.last_match(1))
    end
  end
end

# OUTPUT
# h1
# Herman Melville - Moby-Dick
