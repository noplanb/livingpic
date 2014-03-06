class PushTemplate < NotificationMessageTemplate

  self.config_file = File.join(Rails.root,"config","push_templates.yml")

end
