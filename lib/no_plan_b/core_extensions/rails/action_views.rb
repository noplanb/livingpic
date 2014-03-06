module ActionView
  module Helpers
    # Add the weekday helper
    module FormOptionsHelper
      # Returns the select and options for a select tag for weekdays.  It accepts a few options in addition to the usual Rails ones:
      # :name_format or :value_format, determining the format of the name and values - take the following
      #  +numeric+: if you want the values to be numeric, starting from 1 corresponding to Sunday
      #  +short+: if you want to use 3 letter abbreviated names
      #  +long+: if you want to use the full long names
      # 
      # :first_row: can be a string or array, with format [name,value].  If present, it specifies an added first row to the select
      def weekday_select(object, method, options = {}, html_options = {})
        create_instance_tag(:to_weekday_select_tag,object,method,options,html_options)
      end

      # Returns the select and options for a select tag for months.  For options, see the weekday_select
      def month_select(object, method, options = {}, html_options = {})
        create_instance_tag(:to_month_select_tag,object,method,options,html_options)
      end

      # Returns the select and options for a select tag for years.  It accepts a few options in addition to the usual Rails ones:
      # :name_format or :value_format, determining the format of the name and values - take the following
      #  +short+: if you want to use 3 letter abbreviated names
      #  +long+: if you want to use the full long names
      # 
      # :start: the year to start with (default current year)
      # :count: the number of years to show (default 4)
      # :step: the step between the years (default 1)
      # :first_row: can be a string or array, with format [name,value].  If present, it specifies an added first row to the select
      def year_select(object, method, options = {}, html_options = {})
        create_instance_tag(:to_year_select_tag,object,method,options,html_options)
        # InstanceTag.new(object, method, self, nil, options.delete(:object)).to_year_select_tag(options, html_options)
      end
      private
      
      # IN Rails 1.2.x the initialization method takes five arguments, in Rails 2.x it takes four, w/ some optional
      def create_instance_tag(tag_method,object, method, options = {}, html_options = {})
        # Rails 1.2.x
        if InstanceTag.instance_method(:initialize).arity == -5
          InstanceTag.new(object, method, self, nil, options.delete(:object)).send(tag_method,options, html_options)
        else
          # Rails 2.x
          InstanceTag.new(object, method, self, options.delete(:object)).send(tag_method,options, html_options)
        end
      end
      WEEKDAYS = %w{Sunday Monday Tuesday Wednesday Thursday Friday Saturday}
      MONTHS = %w{January February March April May June July August September October November December}
    end
    
    class InstanceTag #:nodoc:
      def to_weekday_select_tag(options, html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        value = value(object)
        
        names = process_format(options.delete(:name_format) || :long, WEEKDAYS)          
        values = process_format(options.delete(:value_format) || options.delete(:name_format) || :long, WEEKDAYS)
        add_first_row(options.delete(:first_row),names,values)
        content_tag("select", add_options(options_for_select(names.zip(values),value), options, value), html_options)
      end
      
      def to_month_select_tag(options, html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        value = value(object)
        names = process_format(options.delete(:name_format) || :numeric, MONTHS)
        values = process_format(options.delete(:value_format) || options.delete(:name_format) || :numeric, MONTHS)
        add_first_row(options.delete(:first_row),names,values)
        content_tag("select", add_options(options_for_select(names.zip(values),value), options, value), html_options)
      end
      
      def to_year_select_tag(options,html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        value = value(object)
        count = options[:count] || 4
        step = options[:step] || 1
        start = options[:start] || Time.now.year
        stop = start + count*step - 1
        years = []
        start.step(stop,step) { |x| years << x }
        format = options.delete(:name_format) 
        names =  format == :short ? years.map { |y| y.to_s[-2..-1] } : years.map { |y| y.to_s }
        format = options.delete(:value_format) 
        values = format == :short ? years.map { |y| y.to_s[-2..-1].to_i } : years
        add_first_row(options.delete(:first_row),names,values)
        content_tag("select", add_options(options_for_select(names.zip(values),value), options, value), html_options)
      end
      
      private
      
      # Specific to the weekday & month select tags
      def process_format(format,values)
        case format
          when :short then values.map { |w| w[0..2] }
          when :numeric then Range.new(1,values.length).to_a
          when :long then values
          when :lowercase then values.map { |v| v.downcase }
          else values
          end
      end
      
      def add_first_row(fv,names,values)
        if ( fv )
          if !fv.is_a?(String) and fv.respond_to?(:first) and fv.respond_to?(:last)
            names.unshift fv.first
            values.unshift fv.last
          else 
            names.unshift fv.to_s
            values.unshift nil
          end
        end
      end
    end
    
    class FormBuilder
      def weekday_select(method, options = {}, html_options = {})
        @template.weekday_select(@object_name, method, options.merge(:object => @object), html_options)
      end
      
      def month_select(method, options = {}, html_options = {})
        @template.month_select(@object_name, method, options.merge(:object => @object), html_options)
      end

      def year_select(method, options = {}, html_options = {})
        @template.year_select(@object_name, method, options.merge(:object => @object), html_options)
      end
    end
  end
end