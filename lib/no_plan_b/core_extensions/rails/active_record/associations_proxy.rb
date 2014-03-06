module ActiveRecord
  module Associations
    class AssociationProxy #:nodoc:
      private

      def method_missing(method, *args)
        if load_target
          # unless @target.respond_to?(method)
          #   message = "undefined method `#{method.to_s}' for \"#{@target}\":#{@target.class.to_s}"
          #   raise NoMethodError, message
          # end

          if block_given?
            @target.send(method, *args)  { |*block_args| yield(*block_args) }
          else
            @target.send(method, *args)
          end
        end
      end
    end
  end
end
