class UsersController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  before_filter :requires_current_user, :only => [:push_device_token]

  # respond_to :json, :only => [:new]
  
  # Creating a new user from the app directly
  # Passing first and last name only
  # DEprecated - not useful - just use register instead!
  def new
    user  = User.create!(params.only(:first_name,:last_name,:mobile_number).merge(:status => :active)  )
    render :json  =>  user.attributes_for_app 
  end

  # Set the current user and return information about it
  def set
    user = User.find(params[:id])
    set_and_cookie_current_user(user)
    respond_to do |format|
      format.mobile { render :json => user.attributes_for_app }
    end    
  end

  # Get information about a user 
  def show
    user = User.find(params[:id])
    respond_to do |format|
      format.mobile { render :json => user.attributes_for_app }
    end
  end

  # If there is not params id, then there's a problem
  # We update the user's name and specify that he already has the app
  def register
    if params[:id]
      user = User.find(params[:id])
      user.update_attributes(params.only("first_name","last_name").merge(:status => :active,:app_version => params[:v]))
    else
      normalized_mobile_number = PhoneHandling.normalize_phone_number(params[:mobile_number])
      if user = User.find_by_mobile_number(normalized_mobile_number)
        user.status = :active
        user.app_version = params[:v]
        params[:first_name] and user.first_name = params[:first_name]
        params[:last_name] and user.last_name = params[:last_name]
        user.save!
      # Let's check the Notifications to see if this user has been invited...
      elsif n = Notification.to_number(normalized_mobile_number).first
          user = n.recipient
          user.update_attributes(params.only("first_name","last_name").merge(:status => :active,:app_version => params[:v]))
      else
        # Create a new user
        user  = User.create!(params.only("first_name","last_name","mobile_number").merge(:status => :active,:app_version => params[:v])  )
      end
    end
    set_and_cookie_current_user(user)
    render :json  =>  user.attributes_for_app
  end
    
  def update
    if params[:id]
      User.update(params[:id],params.only("first_name","last_name"))
      set_and_cookie_current_user(params[:id])
    else
      log_error_event "Expected id to be passed in an update call: #{params.inspect}"
    end
    render :text => "ok"
  end

  def push_device_token
    if not current_user && params[:id] then set_and_cookie_current_user(params[:id]); end
    if current_user && params[:token]
      current_user.update_push_token(params[:token])
      render :text => "ok"
    else
      logger.warn("push_device_token called but don't know for whom")
    end
  end

  # For debugging right now but we may want to save all the user's contacts at some point
  def contacts
    contacts = params[:contacts].map{|c| c[1]}
    if contacts
      logger.debug ">>> received #{contacts.length} contacts"
    end
    render :text => "ok"
  end
  
  def clear_user
    clear_auth_cookie
    end_user_session  
    render :text => "ok"
  end
  
  # ============================
  # = Notification preferences =
  # ============================
  def unsubscribe_sms
    if current_user
      current_user.update_notification_preference(:push) 
      render :text => "ok"
    else
      render :text => "unknown user"
    end
  end
  
  def subscribe_sms
    if current_user
      current_user.update_notification_preference(nil) 
      render :text => "ok"
    else
      render :text => "unknown user"
    end
  end
  
  # =================================
  # = GARF: For first store release =
  # =================================
  # 
  #  Farhad: Note I didnt want to muck with your register for this password based registration and login which I believe 
  #  is only temporarily going to be used in our first store release. Please feel free to merge or not or do as you will
  #  with this code.
  # 
  def register_with_password
    pu = params[:user]
    if user = User.find_by_email(pu[:email]) 
      # Go ahead and sign the user in if he mistakenly used the signup form to login. But dont bother updating any attributes
      # that area different from the last time he used the sign up screen. 
      if pu[:password] == user.password
        set_and_cookie_current_user user
        render :json => {:success => {:user => user}}
      else
        render :json => {:fail => {:email => user.email}}
      end
    else user = User.create!( pu.merge(:status => :active,:app_version => params[:v]) )
      set_and_cookie_current_user user
      render :json => {:success => {:user => user}}
    end      
  end
  
  def login_with_password
    pu = params[:user]
    if ( user = User.find_by_email(pu[:email]) ) && pu[:password] == user.password
      set_and_cookie_current_user user
      render :json => {:success => {:user => user}}
    else
      render :json => {:fail => {:user => pu}}
    end    
  end
  
  # ===========
  # Get a sample user
  # ===========
  def get_sample_user
    user = case params[:type]
    when "registered"; User.registered.sample
    when "pending"; User.pending.sample
    when "active"; Participation.active.sample.user
    when "unregistered"; User.initialized.sample
    else User.order("RAND()").first
    end
    render :json  => user.attributes_for_app
  end  
end
