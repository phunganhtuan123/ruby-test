# Template: Implements a string substituation template.
#
# The template should look like this:
#
# 'Hi :::name:::, how are you doing :::time:::'
#
# With this template value, you could use the set method to set
# the values "name" and "time" with their appropriate replacement
# values.

# This version of the template class takes a hash for placeholders and values

class Template
  attr_accessor :template, :marker

  # Construct the template object with the template and the
  # replacement values.  "values" can be a hash, a function,
  # or a method.
  def initialize(template: '', marker: ':::', values: {})
    @template = template.to_s
    @values = values.is_a?(Hash) ? values : {}
    @marker = marker.to_s

    @parsed = nil
  end

  def set(name, value)
    @values[name] = value
  end

  # Run the template with the given parameters and return
  # the template with the values replaced
  def parse(force: false)
    return @parsed unless @parsed.nil? || force

    @parsed = @template.clone()
    @parsed.gsub!( /#{marker}(.*?)#{marker}/ ) {
      @values[ $1 ].to_s
    }
    return @parsed
  end

  # Create a new instance with @template content loaded from a file
  def self.from_file(filename: nil, marker: ':::', values: {})
    string = IO.read(filename)
    return self.new(template: string, marker: marker, values: values)
  end

  # A synonym for run so that you can simply print the class
  # and get the template result
  def to_s() parse(); end
end