Axlsx::SheetPr.class_eval do
  # @return [Color]
  attr_reader :tab_color

  # Serialize the object
  # @param [String] str serialized output will be appended to this object if provided.
  # @return [String]
  def to_xml_string(str = '')
    update_properties
    str << "<sheetPr #{serialized_attributes}>"
    tab_color.to_xml_string(str, 'tabColor') if tab_color
    page_setup_pr.to_xml_string(str)
    str << "</sheetPr>"
  end

  # @see tab_color
  def tab_color=(v)
    @tab_color ||= Axlsx::Color.new(:rgb => v)
  end
end
