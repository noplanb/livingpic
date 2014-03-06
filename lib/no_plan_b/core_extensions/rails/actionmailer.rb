require 'rubygems'
require 'action_mailer'

module ActionMailer

  class Base

    # enable partials in ActionMailer templates, there is still a lot to be
    # done to make it work with auto multi-part partials
    def self.controller_path #:nodoc:
      return  ''
    end
    
    # We use the .tst suffix for bogus email addresses - we can write these to the log file instead of 
    # trying to deliver them
    def deliver_with_ignoring_tst_suffixes!(mail=@mail)
      if Array(mail.to).join(',').match(/\.tst$/)
        unless logger.nil?
          logger.info  "Would have sent mail to bogus address #{mail.to.inspect}"
          logger.debug "\n#{mail.encoded}"
        end
      else
        standard_deliver!(mail)
      end
    end
    
    # In rails 3, the deliver! method is gone and replaced with a simple deliver
    if respond_to?(:deliver!)
      alias_method :standard_deliver!, :deliver!
      alias_method :deliver!, :deliver_with_ignoring_tst_suffixes!
    elsif respond_to?(:deliver)
      alias_method :standard_deliver, :deliver
      alias_method :deliver, :deliver_with_ignoring_tst_suffixes
    end
    
  end
  
end