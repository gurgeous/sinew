class Noko < Sinew::Base
  def run
    response = get 'http://httpbingo.org/xml'
    response.noko.css('slide title').each do
      csv_emit(title: _1.text)
    end
  end
end

# OUTPUT
# title
# Wake up to WonderWidgets!
# Overview
