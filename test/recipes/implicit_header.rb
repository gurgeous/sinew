class ImplicitHeader < Sinew::Base
  def run
    csv_emit(name: 'bob', address: 'main')
  end
end

# OUTPUT
# name,address
# bob,main
