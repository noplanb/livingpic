if Rails.version.slice(0,1) == '2'
  module ActiveRecord
    module Validations
      module ClassMethods

        # Keep track of the required attributes so that we can easily
        # query (presumably in the UI as to whether it's required or not)
        def validates_presence_of_with_querying(*attr_names)
          options = attr_names.pop if attr_names.last.is_a?(Hash)
          existing_values = read_inheritable_attribute(:required_attributes) || []
          write_inheritable_attribute(:required_attributes, attr_names | existing_values)
          attr_names.push(options) if options
          validates_presence_of_without_querying(*attr_names)
        end
        alias_method_chain :validates_presence_of, :querying
      
        # The model can be queried to indicate if the item is required or not
        def attr_required?(attr_name)
          required_attributes = read_inheritable_attribute(:required_attributes) || []
          required_attributes.include? attr_name.to_sym
        end
      
      end
    end
  end
end