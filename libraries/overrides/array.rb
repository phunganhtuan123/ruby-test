class Array
  def find_recursive_with arg, options = {}
    first_match = false
    map do |e|
      if e[arg].to_s == options[:parent_id].to_s or options[:find_this_only] or !first_match then
        if (e[arg].to_s == options[:parent_id].to_s) then
          first_match = true
        end
        if first_match or options[:find_this_only] then
          first_match = false
          first = e[arg]
          unless e[options[:nested]].nil?
            others = e[options[:nested]]["items"].find_recursive_with(arg, :nested => options[:nested], :find_this_only => true, :parent_id => options[:parent_id]) unless e[options[:nested]]["items"].nil?
            [first] + (others || [])
          end
        else
          e[options[:nested]]["items"].find_recursive_with(arg, :nested => options[:nested], :find_this_only => false, :parent_id => options[:parent_id]) unless e[options[:nested]]["items"].nil?
        end
      end
    end.flatten.compact
  end

  def category_can_be_deliverable arg, options = {}
    map do |e|
      if e[arg].to_s == options[:find_id].to_s then
        e["deliverable"]
      else
        e[options[:nested]]["items"].category_can_be_deliverable(arg, :nested => options[:nested], :find_id => options[:find_id]) unless e[options[:nested]]["items"].nil?
      end
    end.flatten.compact
  end

  def category_can_be_expensive arg, options = {}
    map do |e|
      if e[arg].to_s == options[:find_id].to_s then
        e["expensive"]
      else
        e[options[:nested]]["items"].category_can_be_expensive(arg, :nested => options[:nested], :find_id => options[:find_id]) unless e[options[:nested]]["items"].nil?
      end
    end.flatten.compact
  end

  def category_info arg, options = {}
    map do |e|
      if e[arg].to_s == options[:find_id].to_s then
        e
      end
    end.flatten.compact
  end

  def sql_literal
    SequelDbConnection.get_connector.literal(self)
  end

  def exclude?(element)
    !include?(element)
  end

  def celluloid_each(&block)
    futures = map.with_index do |element, index|
      next unless element.is_a?(Hash)

      element[:sort_index] = index
      Celluloid::Future.new(element, &block)
    end

    futures.each(&:value)
  end

  def sort_by_index
    sort_by { |element| element[:sort_index] }
  end
end
