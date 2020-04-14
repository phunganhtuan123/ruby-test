class Integer
  def boolean_true?
    if self == 1
      true
    else
      false
    end
  end

  def has_flag?(value)
    self | value === self ? true : false
  end
end
