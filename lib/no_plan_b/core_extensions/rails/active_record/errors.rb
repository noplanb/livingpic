module ActiveRecord
  class Errors

    # Redefine the ActiveRecord::Errors::full_messages method:
    #  Returns all the full error messages in an array. 'Base' messages are handled as usual.
    #  Non-base messages are prefixed with the attribute name as usual UNLESS they begin with '^'
    #  in which case the attribute name is omitted.
    #  E.g. validates_acceptance_of :accepted_terms, :message => '^Please accept the terms of service'
    #  If the string contains %$, the attribute name is substituted
    def full_messages
      full_messages = []

      @errors.each_key do |attr|
        @errors[attr].each do |error|
          next if error.nil?
          msg = error.is_a?(ActiveRecord::ActiveRecordError) ? error.message : error.to_s
          if attr == "base"
            full_messages << msg
          elsif msg =~ /^\^/
            m = msg.sub(/%\$/,@base.class.human_attribute_name(attr))
            full_messages << m[1..-1]
          else
            full_messages << @base.class.human_attribute_name(attr) + " " + msg
          end
        end
      end

      return full_messages
    end
  end
end

module ActiveModel
  class Errors
    # Returns a full message for a given attribute.
    #
    #   company.errors.full_message(:name, "is invalid")  # =>
    #     "Name is invalid"
    def full_message(attribute, message)
      return message if attribute == :base
      attr_name = attribute.to_s.gsub('.', '_').humanize
      attr_name = @base.class.human_attribute_name(attribute, :default => attr_name)
      if message.match(/^[A-Z]/)
        message
      else
        I18n.t(:"errors.format", {
          :default   => "%{attribute} %{message}",
          :attribute => attr_name,
          :message   => message
        })
      end
    end

  end
end
