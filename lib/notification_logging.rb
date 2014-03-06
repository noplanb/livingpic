module NotificationLogging
  
  def self.included(base)
    unless base.respond_to?(:log_notification)
      base.send(:include,InstanceMethods) 
      base.send(:extend,ClassMethods) 
      # base.logger.debug "Added logger to #{base.inspect}"
    end
  end

  module ClassMethods
    def log_notification(*args)
      NotificationLog.simple_log(*args)
    end
  end

  module  InstanceMethods
    def log_notification(*args)
      self.class.log_notification(*args)
    end
  end

  class NotificationLog
    include NoPlanB::SimpleLogging
    configure_simple_logger(:file => "#{::Rails.root}/log/notifications.log", :time_stamp => true)    
  end

end
