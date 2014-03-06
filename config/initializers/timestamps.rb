module ActiveRecord
  module ConnectionAdapters #:nodoc:
    class TableDefinition
      # Appends <tt>:datetime</tt> columns <tt>:created_on</tt> and
      # <tt>:updated_on</tt> to the table.
      # Default rails behavior is to add upated_at,created_at rather than updated_on, created_on
      def timestamps(*args)
        options = { :null => false }.merge(args.extract_options!)
        column(:created_on, :datetime, options)
        column(:updated_on, :datetime, options)
      end
      
    end
  end
end
