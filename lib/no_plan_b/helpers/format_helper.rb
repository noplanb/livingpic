module NoPlanB
  module Helpers
    module FormatHelper
      extend self
      
      # Only works with US phones
      def format_phone(phone,style=:paren)
        return nil unless phone
        num = phone.gsub(/\D/,'')
        case style
        when :paren then "(#{num[0,3]})#{num[3,3]}-#{num[6,4]}"
        when :dash then "#{num[0,3]}-#{num[3,3]}-#{num[6,4]}"
        when :space then "#{num[0,3]} #{num[3,3]} #{num[6,4]}"
        end
      end
      
      
    end
  end
end
    