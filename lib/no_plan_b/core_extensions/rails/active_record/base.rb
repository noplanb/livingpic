# Makes sure that what comes out is an ID
# Used to enabled interfaces to receive IDs or objects as their parameters
# and to be able to easily convert from one to the other
# If you pass it a scalar, it returns a scalar.  If you pass it an array, it returns an array
# Call it as 
# def do_something(user,post)
#   (user_id, post_id) = normalize_to_id([user,post])
#   etc.
# end
# Now you can call this method as
# do_something([User.find(1),Post.find(1)]), or do_something([User.find(1),3]), or do_something([1,3])
#
# or
# def do_something_else(user)
#    user_id = normalize_to_id(user)
# end
# and call it as
# do_something_else(1)
module ActiveRecord
  class Base
    
    def self.normalize_to_object(object)
      self === object ? object : find(object)
    end
    
    def self.normalize_to_id(object)
      object.is_a?(Array) ? object.map{ |o| obj_id(o) } : obj_id(object)
    end

    class <<self
      def obj_id(o)
        p = o.is_a?(Fixnum) ? o : (o.is_a?(String) ? o.to_i : o.id) 
      end
      private :obj_id

      # Trim the input parameters to the attributes so we don't get an error in a mass assignment statement
      # NOTE - this has a bug because it doesn't recognize ruby attributes assigned via attr_accessor 
      def trim_params(params)
        Hash[*(params.select { |k,v| new.attributes.keys.include? k.to_s}.flatten)] 
      end

    end
  
    def normalize_to_id(object)
      self.class.normalize_to_id(object)
    end
    
    def log_info
      "[#{id}] #{respond_to?(:name) ? name : respond_to?(:title) ? title : ''}"
    end

    def scrambled_id(length=12)
      NoPlanB::SimpleScramble.scramble_number(self.id)
    end
    
    def self.find_by_scrambled_id(scrambled_id)
      id = SimpleScramble.unscramble_number(scrambled_id)
      find(id) if id
    end
    
    def calculated_age
      if attributes.include?('created_on') && created_on
        Time.now - created_on
      elsif attributes.include?('created_at') && created_at
        Time.now - created_at
      else
        nil
      end
    end

    # Let's fix up the created_on, created_at mess by making them equivalent
    # If one is defined, then we alias the other one to it
    def method_missing_with_timestamp_aliases(method,*args,&block)
      if method == :created_on && respond_to?(:created_at)
        self.class.send(:alias_method,:created_on,:created_at)
        created_at
      elsif method == :created_on= && respond_to?(:created_at=)
        self.class.send(:alias_method,:created_on=,:created_at=)
        self.created_at = args.first
      elsif method == :created_at && respond_to?(:created_on)
        self.class.send(:alias_method,:created_at,:created_on)
        created_on
      elsif method == :created_at= && respond_to?(:created_on=)
        self.class.send(:alias_method,:created_at=,:created_on=)
        self.created_on = args.first
      elsif method == :updated_at && respond_to?(:updated_on)
        self.class.send(:alias_method,:updated_at,:updated_on)
        updated_on
      elsif method == :updated_at= && respond_to?(:updated_on=)
        self.class.send(:alias_method,:updated_at=,:updated_on=)
        self.updated_on = args.first
      elsif method == :updated_on && respond_to?(:updated_at)
        self.class.send(:alias_method,:updated_on,:updated_at)
        updated_at
      elsif method == :updated_on= && respond_to?(:updated_at=)
        self.class.send(:alias_method,:updated_on=,:updated_at=)
        self.updated_at = args.first
      else
        method_missing_without_timestamp_aliases(method,*args,&block)
      end
    end
    
    alias_method_chain :method_missing,:timestamp_aliases
    
    alias_method :method_missing_before_cm, :method_missing
    def method_missing(method,*args,&block)
      if method.to_s.index('update_') == 0 
        attribute = method.to_s.sub('update_','')
        if attribute_names.include?(attribute)
          self.class.class_eval <<-END,__FILE__,__LINE__
            def #{method}(value)
              update_attribute(#{attribute.to_sym.inspect},value)
            end
          END
          # for some reason I can't just count on method_missing_before_cm to execute this newly defined method
          # because it seems to not be defined for this given object instance
          send(method,*args,&block)
        end
      else
        method_missing_before_cm(method,*args,&block)
      end
    end
  
    # =========================================================
    # = Extensions to find so that it support s the :last parameter =
    # WARNING - not necessarily a good thing
    # =========================================================
    
    class <<self
      
      # Two modifications to the standard find
      # 1) we can supply the term :last in addition to the first, in which case it returns the last entry, equivalent to 'ID DESC' in most cases
      # 2) we can supply a number, as in find(:last,3) to return the last 3 entries
      def find_with_last(*args)
        if args[0] == :last
          args[0] = :first
          options = args.last.is_a?(Hash) ? args.pop : {}
          args.push reverse_order(options)
        end
        if (args[0] == :last || args[0] == :first) && args[1].is_a?(Fixnum)
          options = args.last.is_a?(Hash) ? args.pop : {}
          options[:limit]  =  args[1]
          args.push options
          args[0] = :all if ( args[1] > 1 )
          args.delete_at(1)
        end
        find_without_last(*args)
      end
      alias_method_chain :find, :last
    
      # This retrieves the values for a given attribute
      # return a 2D array sorted by count and including the value and the number of times it appears
      # to only get the first value, just add .column(0)
      # options:
      #  :min_count => minimum number of occurrences must be equal to or greater than this
      #  :conditions => conditions to include in the search
      #  :joins => joins to include in the search
      def values_for(attribute,options = {})
        find(:all,{:select => "#{table_name}.#{attribute}, COUNT(#{table_name}.#{attribute}) as cnt", :group => "#{table_name}.#{attribute}",:order => 'cnt DESC', :having => options[:min_count] ? "cnt >= #{options[:min_count]}" : nil}.merge(options.only(:conditions,:joins))).map{ |x| [x.read_attribute(attribute), x.cnt.to_i] }
      end
      
      private
      def reverse_order(options)
        if options[:order]
          if !options[:order].match(/(desc|asc)/i)
            options[:order] += ' DESC'
          else
            options[:order] = options[:order].gsub(/\basc\b/i,'--tmp--').gsub(/\bdesc\b/i,'ASC').gsub(/--tmp--/,'DESC')
          end
        else
          options[:order] = "#{primary_key} DESC"
        end
        options
      end
    end
    
  end
end

