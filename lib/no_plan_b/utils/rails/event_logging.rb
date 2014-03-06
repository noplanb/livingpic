module NoPlanB
  require File.dirname(__FILE__) + '/../simple_logging'
  module Rails
    module EventLogging
      def self.included(base)
        unless base.respond_to?(:log_event)
          base.send(:include,InstanceMethods) 
          base.send(:extend,ClassMethods) 
          # base.logger.debug "Added logger to #{base.inspect}"
        end
      end

      module ClassMethods
        def log_event(*args)
          EventLog.simple_log(*args)
        end
      end

      module  InstanceMethods
        def log_event(*args)
          self.class.log_event(*args)
        end
      end

      class EventLog
        include NoPlanB::SimpleLogging
        configure_simple_logger(:file => defined?(::Rails) ? "#{::Rails.root}/log/events.log" : 'events.log', :time_stamp => true)    
      end
    end
  end
end

if __FILE__ == $0
  File.delete("events.log")
  class F
    include NoPlanB::Rails::EventLogging
    F.log_event "Something Happened"
  end
  F.new.log_event("Another simple log")
  File.readlines("events.log").each { |line| puts line }
end
