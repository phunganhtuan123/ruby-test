class String
  def is_i?
    !!(self =~ /^[-+]?[0-9]+$/)
  end

  def positive_integer?
    scan(/^[1-9]\d*$/).any?
  end

  def numeric_only
    gsub(/[^0-9\.]/, '')
  end

  def character_only
    gsub(/[^A-Z|a-z\.]/, '')
  end

  def remove_vietnamese_character
    Backend::App::Utility.remove_vietnamese_character self
  end

  def boolean_true?
    if self == '1'
      true
    elsif self == '0'
      false
    elsif self == 'true'
      true
    elsif self == 'false'
      false
    else
      false
    end
  end

  def is_json?
    begin
      !!JSON.parse(self)
    rescue
      false
    end
  end

  # Truncates a given +text+ after a given <tt>length</tt> if +text+ is longer than <tt>length</tt>:
  #
  #   'Once upon a time in a world far far away'.truncate(27)
  #   # => "Once upon a time in a wo..."
  #
  # Pass a string or regexp <tt>:separator</tt> to truncate +text+ at a natural break:
  #
  #   'Once upon a time in a world far far away'.truncate(27, separator: ' ')
  #   # => "Once upon a time in a..."
  #
  #   'Once upon a time in a world far far away'.truncate(27, separator: /\s/)
  #   # => "Once upon a time in a..."
  #
  # The last characters will be replaced with the <tt>:omission</tt> string (defaults to "...")
  # for a total length not exceeding <tt>length</tt>:
  #
  #   'And they found that many people were sleeping better.'.truncate(25, omission: '... (continued)')
  #   # => "And they f... (continued)"
  def truncate(truncate_at, options = {})
    return dup unless length > truncate_at

    omission = options[:omission] || '...'
    length_with_room_for_omission = truncate_at - omission.length
    stop = \
      if options[:separator]
        rindex(options[:separator], length_with_room_for_omission) || length_with_room_for_omission
      else
        length_with_room_for_omission
      end

    "#{self[0, stop]}#{omission}"
  end

  def parse_datetime
    ['%d/%m/%Y %H:%M:%S', '%d/%m/%Y %H:%M', '%d/%m/%Y %H', '%d/%m/%Y'].each do |format_time|
      tmp = Time.strptime(self, format_time) rescue nil
      return tmp if tmp
    end

    raise ArgumentError, 'invalid strptime format'
  end

  def symbolize_keys
    JSON.parse(self, symbolize_names: true)
  end
end
