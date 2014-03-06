class LandingController < ApplicationController
  
  layout "landing"

  def landing
    if params[:notification_id] 
      if @notification = APP_CONFIG[:encode_notification_id] ? Notification.find_by_hash_code(params[:notification_id]) : Notification.find(params[:notification_id])
        set_and_cookie_current_user(@notification.recipient)
       
        # The user has responded to a notification so let's update his definitive info
        @notification.recipient.responded_to_notification(@notification)

        # Set the notification ID in the session so the app can find it via the browser redirect
        session[:notification_id] = @notification.id
        @occasion = @notification.occasion
        @recipient = @notification.recipient
        @invite = Invite.for(@occasion).to_u(@recipient).last
        @inviter = @invite && @invite.inviter
        @occasion_photo = @occasion && @occasion.photo_for_user
        @occasion_photo_url = @occasion_photo && @occasion_photo.pic.url(:original)
        @occasion_photo_aspect = @occasion_photo && @occasion_photo.aspect_ratio
      end
    end
    render :template => "landing/lp_landing"
  end
  alias_method :index, :landing
  
  # Android does not linkify livingpic:// so for our sms messages I need to direct to http://livingpic/fta
  def forward_to_app
    @url = APP_CONFIG[:app_schema] + "?" + request.env["QUERY_STRING"]
    render :template => "landing/forward_to_app", :layout => false
  end
  
  def forward_to_browser_app
    @url = "/app/app?" + request.env["QUERY_STRING"]
    render :template => "landing/forward_to_app", :layout => false
  end
  
end
