module ActiveRecord
  class Base
    
    def self.merge_conditions_with_logic(logic,*conditions)
      return conditions.first if conditions.length < 2
      segments = conditions.inject([]) do |r,condition|
        unless condition.blank?
          sql = sanitize_sql(condition)
          r << sql unless sql.blank?
        end
        r
      end

      %{(#{segments.join(") #{logic.to_s.upcase} (")})} unless segments.empty?
    end
    
    def self.merge_conditions_with_or(*conditions)
      merge_conditions_with_logic(:or,*conditions)
    end
    
    # The logic defines whether we use AND or OR in the merges.  Note that we 
    # can't handle complex logic where there is parenthesizing
    # the logic represented as :and,AND, or and (and their 'or' counterparts)- all work
    def self.merge_conditions_with_logic_old(logic,old_conditions,*new_conditions_array)
      return old_conditions if new_conditions_array.blank?
      old_conditions = sanitize_sql(old_conditions) if old_conditions.is_a?(Hash)
      conditions = old_conditions && old_conditions.dup
      unless conditions.blank?
        conditions = [conditions] if conditions.is_a?(String) 
        conditions[0] = "(#{conditions[0]})" unless conditions[0].blank?
      end
      new_conditions_array.each do |new_conditions|
        next if new_conditions.blank?
        nc = new_conditions.is_a?(Hash) ? sanitize_sql(new_conditions) : new_conditions.dup
        
        conditions = [conditions] if conditions.is_a?(String) && !conditions.blank?
        nc = [nc] if nc.is_a?(String)
        if ( !conditions.blank? )
          conditions[0] += " #{logic.to_s.upcase} (#{nc.shift})"
          conditions += nc 
        else 
          conditions = nc unless nc.blank?
        end
      end
      conditions
    end

    # For compatibility with older merge conditions, we use the AND by default
    def self.param_merge_conditions_with_logic(logic,options,*new_conditions_array)
      options = options.clone
      options[:conditions] = merge_conditions_with_logic(logic,options[:conditions],*new_conditions_array)
      options
    end
    
    def param_merge_conditions_with_logic(logic,options,*new_conditions_array)  
      self.class.param_merge_conditions_with_logic(logic,options,*new_conditions_array)
    end

    # This is supplanted by the merge_conditions that now comes with rails 2.2+
    
    unless self.respond_to?(:merge_conditions)      
      # puts "Defining merge conditions"
      def self.merge_conditions(old_conditions, *new_conditions_array)
        merge_conditions_with_logic(:and, old_conditions, *new_conditions_array)
      end
    else
      # puts "merge_conditions already defined"
    end
            
    # Merge the conditions into the :conditions key of the options hash
    # Returns the merged conditions
    def self.param_merge_conditions(options,*new_conditions_array)
      options = options.clone
      options[:conditions] = merge_conditions(options[:conditions],*new_conditions_array)
      options
    end
    
    def param_merge_conditions(options,*new_conditions_array)  
      self.class.merge_param_conditions(options,*new_conditions_array)
    end
    
    def self.add_time_conditions(conditions,field_name,start_time,end_time)
      field_name = field_name.to_s
      conditions = merge_conditions(conditions,["#{field_name} >= ?",start_time]) if start_time
      conditions = merge_conditions(conditions,["#{field_name} < ?",end_time]) if end_time
      conditions
    end
    
    def add_time_conditions(*args)
      self.class.add_time_conditions(*args)
    end
   
    # add a prefix to the column names in the given sql (nominally the existing class name)
    # I'm sure rails already has something like this, but I can't find it...
    # If the item is already prefixed, we replace it with the new prefix
    # The sql should be simple in that it only has AND and OR conditions, it should not
    # have joins or otherwise
    # WARNING - this doesn't handle complex parentheses
    def self.prefix_column_names_in_condition(condition_sql,prefix=nil)
      
      return condition_sql if condition_sql.blank?
      
      condition_sql = sanitize_sql(condition_sql) unless condition_sql.is_a?(String)

      condition_sql = condition_sql.gsub(/\(\s+/,'(').gsub(/\s+\)/,')')
      # puts "conditions sql = #{condition_sql}"
      prefix ||= self.table_name
      segments = condition_sql.split(/\s+(?:AND|OR)\s+/i)
      # puts "segments = #{segments.inspect}"
      # The column names are the first word in each of the segments
      s = condition_sql
      logic = []
      while m= s.match(/\s+(AND|OR)\s+/i)
        logic << m[1]
        s= m.post_match
      end
      sub_condition_sql = ''
      segments.each { |seg|
        # puts "adding the prefix for segment #{seg}"
        seg.strip!
        column_name = seg.match(/([\w.'"]+)/) && $1
        if n = column_name.index('.')
          seg = prefix + seg[n..-1]
        else
          seg.sub!(column_name,"#{prefix}.#{column_name}")
        end
        sub_condition_sql += seg + " #{logic.shift} "
      }
      sub_condition_sql
    end
  end    
end