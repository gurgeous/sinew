class Limit < Sinew::Base
  def initialize(options)
    super(options.merge(limit: 3))
  end

  def run
    (1..5).each { csv_emit(i: _1) }
  end
end

# OUTPUT
# i
# 1
# 2
# 3
