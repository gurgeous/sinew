class ArrayHeader < Sinew::Base
  def run
    csv_header(%i[n a p z])
    csv_emit(n: 'n1', a: 'a1')
  end
end

# OUTPUT
# n,a,p,z
# n1,a1,,
