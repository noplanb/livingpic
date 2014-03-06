class AppController < ApplicationController
 
  skip_before_filter :verify_authenticity_token
  
  layout "app"
  
  helper NotificationHelper
  
  # Note this stuff belongs in user but I have it here because it is what loads the app and I dont want all the 
  # views for the app under user.
  # Either this is a startup launch, in which case we might want to start fresh, or else it's invoked via 
  # a redirect
  def app
    ENV['PRECOMPILE_TARGET'] = 'browser'
    ENV['BROWSER_RELEASE_VERSION'] = Version.current_string
    # @invoked_via_message = true if params[:u] || params[:c]
    # @fresh = params[:fresh]
    respond_to do |format|
      format.mobile {render  :template => "app/app"}
    end
  end
  alias_method :index, :app
  
  # Called to set the store release version
  def store_release
    # Need both so that sprockets can recompile all assets for device and browser.
    ENV['PRECOMPILE_TARGET'] = 'browser'
    ENV['BROWSER_RELEASE_VERSION'] = 'store_b.0.0'
    respond_to do |format|
     format.mobile {render  :template => "app/app"}
    end
  end

  # Is called by the app if it needs to check the cookies to get a clue about the user
  # The idea is that the user may have already been cookied by the landing page
  # We set the "app=true" to indicate that it's coming from the app so the correct
  # redirect is set
  def check_cookies
    # the context for this user is the notification ID that was set by the landing page
    @context_id = session[:notification_id] || 'nil'
    @using_app = params[:app]
    session[:using_app] = params[:app]
    logger.info("check_cookies: context id = #{@context_id}, using_app = #{@using_app}")
    render :template => "/app/check_cookies", :layout => "landing"
  end
  
  # Returns information about the user's notification context
  # the type parameter indicates what type of notification it was: e.g Invite or PhotoTagging
  # Only support json
  def get_context_info
    if notification = APP_CONFIG[:encode_notification_id] ? Notification.find_by_hash_code(params[:id]): Notification.find(params[:id])
      notification.update_status(:clicked)
      notification.recipient.update_attribute(:app_version,params[:v]) 
      notification.recipient.responded_to_notification(notification)
      respond_to do |format|
        if notification.recipient.is_registered? && current_user_id
          # type = [ Photo, Comment].include?(notification.trigger.class) ? "Occasion" : notification.trigger.class.name
          type = notification.trigger.class.name
        else
          # If the user is not registered, make the client think thi is an invite, so that it takes him through the 
          # invite sequence
          type = "Invite"
        end

        response = {
          :type => type,
          :user => notification.recipient.attributes_for_app,
        }
        case notification.trigger
        when Comment, Like then 
          response = response.merge :photo => notification.trigger.photo.attributes_for_app
        when Photo 
          response = response.merge :photo => notification.trigger.attributes_for_app
        else
          response = response.merge :occasion => notification.occasion.attributes_for_app
        end

        format.mobile { render :json => response }
      end
    else
      render :json => {}
    end
  end

  # The app is checking in, so we can set the appropriate cookie
  def checkin
    if params[:id] and user = User.find_by_id(params[:id])

      # It's possible that an existing user will check in with the 
      if current_user_id && user.id != current_user_id
        logger.warn "Existing user ID #{current_user_id} checking in with user ID #{user.id}"
      end

      set_and_cookie_current_user(params[:id])
      # Set the fact that the user has the app and its version number, and track his device
      user.update_attribute(:app_version,params[:v]) 

      # Update the push token
      user.update_attribute(:push_token, params[:pt]) unless params[:pt].blank?

      user.has_device(platform: params[:p],platform_version:params[:pv])
      render :text => "OK"
    else
      clear_auth_cookie
      set_tmp_user(-rand(10000000)) unless tmp_user_id 
      logger.info "Checkin w/ nonexistant user id: #{params[:id] || 'NIL'} so set tmp_user_id to #{tmp_user_id}"
      if params[:id] and params[:id].to_i > 0 
        render :status => MobileApp.error_code(:user_not_found), :text => "User Not Found" and return
      else
        # If you checkin w/o an id, we don't consider it an error
        render :text => "OK"
      end
    end
  end

  # A very lightweight method for testing connectivity
  def ping
    # raise "BAD"
    render :text => "OK"
  end

  # Get dummy contact list data from server until we have a packaged app which can get this from the 
  # phone itself.
  # GARF - replace this with a real list
  def get_contacts
    render :file => "#{Rails.root}/lib/tasks/contact_list_test_data/data/cordova_format.json"
  end
    
  # Returns the host URI
  def host
    logger.debug request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"]
    render :json => {:host_uri => request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"]}
  end

  def upload_log
    log_file = current_user ? "device_log_#{current_user_id}" : "device_log"
    file = params[:file]
    dir = Rails.root.join('log', 'device_logs')
    Dir.mkdir(dir) unless Dir.exist?(dir)
    File.open(File.join(dir,log_file), 'a') do |f|
      f.puts("-"*40)
      f.write(file.read)
    end
    render :text => "OK"
  end

  # ===============
  # = Version Mgt =
  # ===============
  def version_mgt_checkin
    severity = Version.out_of_date_severity params[:version]
    render :json => { :out_of_date => severity, :store_link => store_link }
  end
  
  # This is asked for by the device to see if there are any remote commands
  # It expects a JSON response
  def remote_command
    # render :json => {command: "send_log"}
    render :json => {}
  end

  # ==================
  # = Build  targets =
  # ==================
  
  def build_page
    ENV['PRECOMPILE_TARGET'] = 'device'
    ENV['DEVICE_RELEASE_VERSION'] = params[:device_release_version]
    @device_type = params[:device_type] && params[:device_type].to_sym
    puts "Build device_type = #{@device_type.inspect}, release version = #{ENV['DEVICE_RELEASE_VERSION']}"
    render :template => "app/app.mobile", :layout => "app_package"
  end
  
  # ========================
  # = Web splash page stub =
  # ========================
  def web_splash
    render "#{Rails.root}/app/views/web/splash.html"
  end
  
  # ================
  # = Test methods =
  # ================
  def test_set
    session[:browser_cookie] = "browser_cookie"
    render :text  => "SET session[:browser_cookie]=#{session[:browser_cookie].inspect}"
    # render :template => "/app/test"
  end
  
  def test_get
    render :text  => "GET session[:browser_cookie]=#{session[:browser_cookie].inspect}"
  end
  
  def tl
    render :template => "/web/test", :layout => "landing"
  end
  
  def test_no_layout
    render :template => "/app/test", :layout => false
  end
  
  def test_get_date
    render :json => {:time_now => Time.now, :created_on => User.first.created_on}
  end
  
  def test_post_json
  end
  
  def test_post_date
    logger.debug params[:test_date]
    logger.debug params[:test_date].class
    logger.debug Date.parse(params[:test_date]).inspect
    logger.debug Date.parse(params[:test_date]).class
    render :text => "ok"
  end
  
end
