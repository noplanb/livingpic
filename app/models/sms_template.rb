class SmsTemplate < NotificationMessageTemplate

  self.config_file = File.join(Rails.root,"config","sms_templates.yml")

end

