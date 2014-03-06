module ActionView
  module Helpers

    module FormOptionsHelper
      
      # This is a private method we override to get rid of the issue with integers and strings
      def option_value_selected?(value, selected)
        if selected.respond_to?(:include?) && !selected.is_a?(String)
          selected.map(&:to_s).include? value.to_s
        else
          value.to_s == selected.to_s
        end
      end
    end

  end
end