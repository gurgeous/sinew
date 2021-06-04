class Sample < Sinew::Base
  def run
    response = get 'http://httpbingo.org'
    response.noko.css('ul li a').each do |a|
      row = {}
      row[:url] = a[:href]
      row[:title] = a.text
      csv_emit(row)
    end

    get 'http://httpbingo.org/redirect/2'
  end
end
