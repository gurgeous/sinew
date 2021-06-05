class Xml < Sinew::Base
  def run
    response = get 'http://httpbingo.org/html'
    response.noko.css('h1').each do
      csv_emit(h1: _1.text)
    end
  end
end

# OUTPUT
# h1
# Herman Melville - Moby-Dick
