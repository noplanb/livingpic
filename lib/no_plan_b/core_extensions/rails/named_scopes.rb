module NoPlanB::NamedScopes

  # Add a bunch of useful named scoped items that are generally applicable
  def self.included(base)
    begin
      created_on_column = base.column_names.include?('created_on') ? "#{base.table_name}.created_on" : base.column_names.include?('created_at') ? "#{base.table_name}.created_at" : nil
      if created_on_column
        base.class_eval <<-END, __FILE__, __LINE__
          scope :created_since, lambda { |t| 
            if t then {:conditions => ['#{created_on_column} > ?',t] } else {}; end
          }

          scope :created_from_to, lambda { |from,till|
            if from && till && from > till then x = from; from = till; till = x;  end;
            if from && till
              {:conditions => ["#{created_on_column} >= ? AND #{created_on_column} < ?",from,till]}
            elsif from
              {:conditions => ["#{created_on_column} >= ?",from]}
            elsif till
              {:conditions => ["#{created_on_column} < ?",till]}
            else
              raise "Expecting :from and/or :to values as arguments" 
            end
          }
        
        END
      end

      # Create a general method for extracting timestamped values
      # Usage: User.timestamped(:registered,:from => 3.days.ago)
      base.class_eval <<-END, __FILE__, __LINE__
        scope :timestamped, lambda { |*args|
          attribute_name,options = args[0],args[1]
          full_attribute_name = "#{base.table_name}" + '.' + attribute_name.to_s
          raise "Expecting :from and/or :to values" unless Hash===options && (options[:to] || options[:from])
          from = options[:from]
          till = options[:to]
          if from && till
            {:conditions => [full_attribute_name.to_s + " >= ? AND " + full_attribute_name.to_s + " < ?",from,till]}
          elsif from
            {:conditions => [full_attribute_name.to_s + " >= ?",from]}
          elsif till
            {:conditions => [full_attribute_name.to_s + " < ?",till]}
          else
            raise "Expecting :from and/or :to values" 
          end
        }

        scope :value_match, lambda { |*args|
          attribute_name,options = args[0],args[1]
          full_attribute_name = "#{base.table_name}" + '.' + attribute_name.to_s
          if Hash === options
            from = options[:from]
            till = options[:to]
            if from && till
              {:conditions => [full_attribute_name.to_s + " >= ? AND " + full_attribute_name.to_s + " <= ?",from,till]}
            elsif from
              {:conditions => [full_attribute_name.to_s + " >= ?",from]}
            elsif till
              {:conditions => [full_attribute_name.to_s + " <= ?",till]}
            else
              raise "Expecting :from and/or :to values" 
            end
          else
            {:conditions => {attribute_name => options}}
          end
        }
        
      END

      if base.column_names.include?('user_id')
        base.class_eval <<-END, __FILE__, __LINE__
          scope :for_user, lambda { |arg| {:conditions => {:user_id => arg} }}
        END
      end
      
    rescue  => e
      puts "Warning - could not include default named scopes because of #{e.inspect}"
    end
  end
  
end
