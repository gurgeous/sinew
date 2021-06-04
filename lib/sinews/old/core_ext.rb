#
# A few core extensions brought over from ActiveSupport. These are handy for
# parsing.
#

class String
  def squish
    dup.squish!
  end

  def squish!
    strip!
    gsub!(/\s+/, ' ')
    self
  end

  def first(limit = 1)
    if limit == 0
      ''
    elsif limit >= size
      dup
    else
      self[0..limit - 1]
    end
  end

  def last(limit = 1)
    if limit == 0
      ''
    elsif limit >= size
      dup
    else
      self[-limit..]
    end
  end

  alias starts_with? start_with?
  alias ends_with? end_with?
end

#
# blank?/present?
#

class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  def present?
    !blank?
  end
end

class String
  def blank?
    !!(self =~ /\A\s*\z/)
  end
end
