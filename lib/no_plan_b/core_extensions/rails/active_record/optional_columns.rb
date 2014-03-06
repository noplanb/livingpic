# Need to extend with this module
module NoPlanB
  module AR
    module OptionalColumns
      module Base

        # A couple of methods for faking columns
        def has_column?(column_name)
          column_names.include?(column_name.to_s)
        end

        protected

        def define_optional_columns(*column_names)
          column_names.each do |column_name|
            unless has_column?(column_name)
              logger.info "Defining accessors for optional column #{column_name} since it's not in database"
              attr_accessor column_name.to_sym
            end
          end
        end

      end
    end
  end
end

