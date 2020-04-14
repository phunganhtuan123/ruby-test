# This module used to add some methods to model want to checking attributes values changes
# ex: Model: Product[price, stock] when apply this module, it add 3 new methods to each instances:
# price_was: price value before change value
# price_changed?: return true if price changed otherwise false
# reset_checking_changes: To reset the changes state, used when object sync with DB (bottom of save method)!
# same as stock,...

module CheckingFieldsChanged
  def  self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def fields_to_checking_changes(*fields_name)
      @fields_to_checking_changes ||= fields_name

      if @fields_to_checking_changes.is_a?(Array) && @fields_to_checking_changes.any?
        @fields_to_checking_changes.each do |method_name|
          define_method("#{method_name}_was") do
            instance_variable_get("@#{method_name}_was")
          end

          define_method("#{method_name}_changed?") do
            instance_variable_get("@#{method_name}_was") != send(method_name)
          end
        end
      end

      define_method('reset_checking_changes') do
        Object.const_get(self.class.name).fields_to_checking_changes.each do |method_name|
          instance_variable_set("@#{method_name}_was", send(method_name))
        end
      end

      define_method('init_fields_was') do
        fields = Object.const_get(self.class.name).fields_to_checking_changes
        if fields.is_a?(Array)
          fields.each do |method_name|
            instance_variable_set("@#{method_name}_was", send(method_name))
          end
        end
      end

      @fields_to_checking_changes
    end
  end
end
