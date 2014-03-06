class AdminController < ApplicationController

  # Set the user to a specific user
  def set_user
    @using_app = params[:app] || session[:using_app]
    @users = User.all
    render :template => "/admin/users", :layout => "admin_mobile"
  end

  def set_notification
    @using_app = params[:app] || session[:using_app]
    if params[:uid]
      @notifications = Notification.where(:recipient_id => params[:uid])
    else
      @notifications = Notification.last(40)
    end
    render :template => "/admin/notifications", :layout => "admin_mobile"
  end

  def view_notification
    @notification = Notification.find(params[:id])
    render :template => "/admin/notification_body", :layout => "admin_mobile"
  end
  
  def notification_gen
    if request.method == "GET"
      render :template => "/admin/notification_gen", :layout => "admin_mobile"
    else
      Notification.enable!
      if params[:type] == "invite"
        i = Invite.create({:inviter_id => params[:inviter_id].to_i, :invitee_id => params[:invitee_id].to_i, :occasion_id => params[:occasion_id].to_i})
        n = i.notifications.last
      end
      
      if params[:has_app] == "false"
        n.recipient.update_app_version(nil)
        n.recipient.update_status(:initialized)
      else
        n.recipient.update_app_version("test_v") unless n.recipient.app_version
      end
      
      
      render :text => n.body
    end
  end
    
  
  # view session
  def vs
    @session =  session.to_hash
    render :template => 'admin/session.html.erb', :layout => "admin_mobile"
  end

end

