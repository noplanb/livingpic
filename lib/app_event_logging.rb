module AppEventLogging
  
  def self.included(base)
    unless base.respond_to?(:log_app_event)
      base.send(:include,InstanceMethods) 
      base.send(:extend,ClassMethods) 
      # base.logger.debug "Added logger to #{base.inspect}"
    end
  end

  module ClassMethods
    def log_app_event(*args)
      AppEventLog.simple_log(*args)
    end
  end

  module  InstanceMethods
    def log_app_event(*args)
      self.class.log_app_event(*args)
    end
  end

  class AppEventLog
    include NoPlanB::SimpleLogging
    configure_simple_logger(:file => "#{::Rails.root}/log/app_events.log", :time_stamp => true)    
  end

end
