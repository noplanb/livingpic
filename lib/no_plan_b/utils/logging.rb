# To be included in whatever method needs the logger
# if logger is not already defined, this will define it
# This allows you to specify a separate log file, using the configure_logger directive
# configure_logger takes the following options:
#  :file => 'full file path'  defines the file to use for the log file (default, just use rails log)
#  :copy_to_rails_log => boolean, if set & we have specified our own log file, we also write the messages to the rails log
#  :naked_methods => boolean, if set, it defines methods debug, warn, error, and info (not defined if naked_methods is not specified)
# E.g.
# class Foo
#  include NoPlanB::Logging
#  configure_logger(:file => 'foo.log',:naked_methods => true)  # creates a log file named foo.log,and defines log methods
#  debug "This is a debug message" 
# end
# class Bar
#  include NoPlanB::Logging
#  configure_logger(:file => 'bar.log')  # creates a log file named foo.log,and defines log methods
#  logger.info("This is an info message")
# end
# See also the test methods at the end of this file

# TODO - don't hardcode the logger level to :DEBUG - make it configurable via the configure_logger method params
#      - change so that we can create a specific logger w/ a prefix, so for exmaple, and instance can write to a log file with 
#        a particular prefix (e.g user_id) so it's easier to track when we have multiple threads/processes writing to the log file
module NoPlanB
  module Logging

    # Require the ruby logger
    require 'logger'
    
    def self.included(base)
      unless base.respond_to?(:logger)
        base.send(:include,InstanceMethods) 
        base.send(:extend,ClassMethods) 
        # base.logger.debug "Added logger to #{base.inspect}"
      end
    end
    
    module ClassMethods
      attr_reader :log_file
      attr_accessor :copy_to_rails_log, :naked_methods
      
      def configure_logger(params)
        params.each do |param,value|
          send("#{param}=".to_sym,value)
        end
        if @naked_methods
          class_eval NAKED_METHODS_DEF
          class << self
            class_eval NAKED_METHODS_DEF
          end
        end
      end
      
      # If naked methods are not used, this is the method to use for logging
      def logger
        @my_logger or defined?(::Rails) ? ::Rails.logger : raise("Please run configure_logger or use w/in rails environment")
      end
      
      # Define a number of methods that can be easily accessed from within the module
      # the problem is that these could conflict with any predefined methods that may already be there, so they're only
      # done if the define method is used
      NAKED_METHODS_DEF = <<-END
        %w(debug info warn error).each do |level|
          define_method(level) { |str| 
            logger.send(level,str)
            # if copy_to_rails_log is set, and we have our own logger, then copy to the normal log using the default RAILS logger
            if @copy_to_rails_log && @my_logger && defined?(RAILS_DEFAULT_LOGGER)
              RAILS_DEFAULT_LOGGER.send(level,str)
            end
          }
        end
      END
            
      private 
      
      # If the config file is set, we make sure that it exists.
      def file=(value)
        @log_file = value
        set_log(value)
      end
      
      def set_log( filename )
        @my_logger = ::Logger.new filename
        @my_logger.level = ::Logger::DEBUG
        @my_logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      end

    end
    
    module InstanceMethods
      def logger(*args)
        self.class.logger(*args)
      end   
      
      def configure_logger(*args)
        self.class.configure_logger(*args)
      end   
    end

  end
end

# Just some test code
if __FILE__ == $0
  # Test the first way of doing this....
  class Foo 
    include NoPlanB::Logging
    configure_logger(:file => 'foo_logger.log')
    
    def some_method
      logger.debug "Debug in some_method"
    end
    
    warn "This had better work"
  end

  class Bar
    include NoPlanB::Logging
    configure_logger(:file => 'foo_logger.log', :naked_methods => true)
    
    def some_method
      debug "naked debug in some_method"
    end
    
    error "This isn't really an error"
  end
  
  Foo.logger.debug("This is a test")
  f=Foo.new
  f.logger.debug("Debug called from f")
  f.some_method

  Bar.error("This is a naked error test")
  b=Bar.new
  b.debug("Debug called from b")
  b.some_method

end
