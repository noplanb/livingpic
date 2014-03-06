class PushNotification
  
  #- PushWoosh API Documentation http://www.pushwoosh.com/programming-push-notification/pushwoosh-push-notification-remote-api/
  #- Two methods here:
  #     - PushNotification.new.notify_all(message) Notifies all with the same option
  #     - PushNotification.new.notify_devices(notification_options = {}) Notifies specific devices with custom options
 
  include HTTParty

#   default_params <img src="http://www.pushwoosh.com/wp-includes/images/smilies/icon_surprised.gif" alt=":o" class="wp-smiley"> utput => 'json'
#   format :json
 
  def initialize
    #- Change to your settings
    @auth = {:application  => APP_CONFIG[:pushwoosh_app_id],:auth => APP_CONFIG[:pushwoosh_auth_token]}
  end
 
  # PushNotification.new.notify_all("This is a test notification to all devices")
  def notify_all(message)
    notify_devices({:content  => message})
  end
 
  # PushNotification.new.notify_device(devices, content, {
  #  :content  => "TEST",
  #  :data  => {:custom_data  => value},
  #  :devices  => array_of_tokens
  #})
  def notify_devices(params = {})
    #- Default options, uncomment :data or :devices if needed
    params[:content] or raise "PushNotification: please supply content"
    # params[:devices] or raise "PushNotification: you must supply device tokens"
    #- Constructing the final call
    options = @auth.merge({:notifications  => [{:send_date  => "now"}.merge(params)]})
    request_params = {:request  => options}
    #- Executing the POST API Call with HTTPARTY - :body => options.to_json allows us to send the json as an object instead of a string
    response = self.class.post("https://cp.pushwoosh.com/json/1.3/createMessage", :body  => request_params.to_json,:headers => { 'Content-Type' => 'application/json' })
  end
end
