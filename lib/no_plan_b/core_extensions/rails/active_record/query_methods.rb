module ActiveRecord
  module QueryMethods

    def build_where_with_association_substitutions(opts,other=[])
      return self if opts.blank?

      if Hash === opts 
        associations = reflect_on_all_associations
        new_opts = {}
        opts.each do |name,value|
          if (Symbol === name || String === name ) && Base === value && ass = associations.detect { |a| a.name == name }
            if ass.options[:polymorphic]
              new_opts[ass.options[:class_name] || "#{name}_type".to_sym] = value.class.name            
            end
            new_opts[ass.options[:foreign_key] || "#{name}_id".to_sym] = value.id
          else
            new_opts[name] = value
          end 
        end
        # puts new_opts.inspect
      else
        new_opts = opts
      end
      build_where_without_association_substitutions(new_opts,other)      
    end

    alias_method_chain :build_where, :association_substitutions

    if false
      # Redefine the "where" query method so that it recognizes that some elements
      # may be association objects
      # this seems to work
      def where(opts, *rest)
        return self if opts.blank?

        associations = reflect_on_all_associations
        new_opts = {}
        opts.each do |name,value|
          if ass = associations.detect { |a| a.name == name }
            if ass.options[:polymorphic]
              new_opts[ass.options[:class_name] || "#{name}_type".to_sym] = value.class.name            
            end
            new_opts[ass.options[:foreign_key] || "#{name}_id".to_sym] = value.id
          else
            new_opts[name] = value
          end 
        end
        relation = clone
        relation.where_values += build_where(new_opts, rest)
        relation
      end
    end

  end
end