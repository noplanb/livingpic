module NoPlanB
  require File.dirname(__FILE__) + '/../simple_logging'
  ERROR_LOG_FILENAME = 'error_events.log'
  module Rails
    module ErrorLogging
      def self.included(base)
        unless base.respond_to?(:log_event)
          base.send(:include,InstanceMethods) 
          base.send(:extend,ClassMethods) 
        end
      end

      module ClassMethods
        # Method log_error is already used by rails already for implementing a custom
        # error logger, so use a different,if less appealing name
        def log_error_event(*args)
          ErrorLog.simple_log(*args)
        end
      end

      module  InstanceMethods
        def log_error_event(*args)
          self.class.log_error_event(*args)
        end
      end

      class ErrorLog
        include NoPlanB::SimpleLogging
        configure_simple_logger(:file => defined?(::Rails) ? "#{::Rails.root}/log/#{ERROR_LOG_FILENAME}" : ERROR_LOG_FILENAME, :time_stamp => true)    
      end
    end
  end
end

if __FILE__ == $0
  File.delete(NoPlanB::ERROR_LOG_FILENAME) if File.exists?(NoPlanB::ERROR_LOG_FILENAME)
  class F
    include NoPlanB::Rails::ErrorLogging
    F.log_error_event "Something Happened"
  end
  F.new.log_error_event("Seems to be working")
  File.readlines("errors.log").each { |line| puts line }
end
