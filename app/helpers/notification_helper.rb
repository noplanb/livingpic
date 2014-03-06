module NotificationHelper
  # This is the landing link that comes from this notification
  # You can force the has_app
  def click_link(notification,device=nil)
    device.nil? && device = notification.recipient.device 
    if device
      if device.is_ios?
        APP_CONFIG[:app_schema] + "?#{encode_notification_context(notification)}"
      else
        APP_CONFIG[:site_url] + "/fta?#{encode_notification_context(notification)}"
      end
    else
      # GARF!!! HACK!!! 
      (dev_mode? ? "http://" + NoPlanB::MyIp.local_ip + ":3000" :  APP_CONFIG[:site_url]) + "/l/#{notification_id(notification)}"
    end
  end
    
  def new_creator_names(notification)
    new_creators = notification.occasion.new_photos_for(notification.recipient).reverse.map{|p| p.creator}.uniq 
    if false
      new_creators = new_creators - User.admin_users
      return "Someone" if new_creators.blank?
    end
    return new_creators.map{|c| c.first_li}.first(5).to_sentence
  end
  
  def new_commenter_names(notification)
    if (new_comments = notification.occasion.new_comments_for(notification.recipient)).empty? && Comment === notification.trigger
      new_comments = [notification.trigger]
    end
    new_comments.reverse.uniq_by(&:user_id).map{ |c| c.user.first_li }.first(3).to_sentence
  end
  
  def new_liker_names(notification)
    if (new_likes = notification.occasion.new_likes_for(notification.recipient)).empty? && Like === notification.trigger
      new_likes = [notification.trigger]
    end
    new_likes.reverse.uniq_by(&:user_id).map{ |c| c.user.first_li }.first(3).to_sentence
  end
  
  private

  def notification_id(notification)
    notification ? (APP_CONFIG[:encode_notification_id] ? notification.hash_code : notification.id) : nil
  end

  # A common method for encoding the notification context - whether we use ID or hash_code we can do it here
  def encode_notification_context(notification=nil)
    "c=#{notification_id(notification)}"
  end
end