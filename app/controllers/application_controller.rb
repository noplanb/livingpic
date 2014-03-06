class ApplicationController < ActionController::Base
  protect_from_forgery

  include SessionManager, Commons

  before_filter :check_on_entry, :adjust_format_for_mobile
  before_filter :determine_current_user
  
  # Make sure the env precompile_target isnt set from a recent build_page call
  before_filter :clear_precompile_target
  after_filter :clear_precompile_target

  before_filter :sprockets_js_erb_cache_bust
  after_filter :update_last_user_activity
  
  # Cleaning up after doesnt work. Apparently sprockets does its thing after the after_filter.
  # after_filter :sprockets_js_erb_cache_bust_cleanup 

  private
  
  # GARF This may have performance issues
  # Make sprockets process all js.erb files by changing a timestamp comment at the top of the file.
  # From my experiments touching the file in the filesystem was not enough there had to be a change 
  def sprockets_js_erb_cache_bust
    do_sprockets_cache_bust(:time_stamp)
  end
  
  def sprockets_js_erb_cache_bust_cleanup
    do_sprockets_cache_bust(:clean_up)
  end
  
  def do_sprockets_cache_bust(action)
    return unless ENV["RAILS_ENV"] == "development"
    path = File.join(Rails.root, "app", "assets", "javascripts", "project", "*", "*.js.coffee.erb")
    paths = Dir.glob path
    paths.each{|path| action == :clean_up ? remove_time_stamp(path) : add_time_stamp(path)}
  end
  
  # Change the timestamp at the top of the file. 
  def add_time_stamp(path)
    logger.debug "sprockets cache busting: #{File.basename path}"
    lines = File.readlines path
    lines.slice!(0) if lines.first.match(/^#=Timestamp/)
    lines = ["#=Timestamp #{Time.now}\n"] + lines
    File.open(path, "w") do |f|
      lines.each{|l| f.write l}
    end
  end
  
  def remove_time_stamp(path)
    lines = File.readlines path
    lines.slice!(0) if lines.first.match(/^#=Timestamp/)
    File.open(path, "w") do |f|
      lines.each{|l| f.write l}
    end
  end
  
  # Very primitive user agent detection.  There are better, more complex models out there that check
  # against the OS and other parameters also
  def mobile_user_agent?
    request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/\b(ipod|iphone|android|ipad|ios)\b/i]
  end

  def adjust_format_for_mobile
    # logger.debug ">>>>> User agent: #{request.env["HTTP_USER_AGENT"]}"
    if mobile_user_agent?
      request.format = :mobile 
    end
  end

  def using_mobile?
    mobile_user_agent?
  end
  

  # If the user has a cookie and we don't already have a user, then set the current user
  def set_current_user_from_cookie
    if !current_user_id && auth_cookie 
      user = User.find_by_auth_token(auth_cookie)
      set_current_user( user )
      if current_user
        logger.info("Logging in user #{current_user.log_info} based upon auth cookie") 
      else
        logger.warn("Unable to log in user based upon auth cookie #{auth_cookie}") 
      end
    end
    current_user_id
  end  

  # For some calls the device state comes in as a json object
  def normalize_state_variables
    if params[:device_state]
      x = JSON.parse(params[:device_state]).deep_symbolize_keys
      params[:device_state] = JSON.parse(params[:device_state]).deep_symbolize_keys
    end
    if params[:app_info] && params[:app_info].is_a?(String)
      x = JSON.parse(params[:app_info]).deep_symbolize_keys
      params[:app_info] = JSON.parse(params[:app_info]).deep_symbolize_keys
    end
  end

  # The current user may not be cookied if something went wrong
  # with the cookies.  So if the user is specfied in the parameters,
  # just use that
  def set_current_user_from_message
    if params[:app_info]
      if params[:app_info][:user_id] && params[:app_info][:user_id]
        set_and_cookie_current_user(params[:app_info][:user_id])
      end
    end
    current_user_id
  end

  def determine_current_user
    (set_current_user_from_cookie || set_current_user_from_message) unless current_user_id
  end

  # TODO - not sure what to do if there already is a current user
  def set_current_user_from_notification_id
    if params[:notification_id]
      # Notification.find_by_
    end
  end
   
  # TODO - if we don't have a current user, and we should, we need to send a message back to the app
  # to try to get the current user again?
  def requires_current_user
    render :text => "User login required", :status => 401 unless current_user_id
  end

  def check_on_entry
    session[:start] ||= Time.now
    clear_log_notes
  end

  def display_message_page(message)
    @message = message
    render :template => "shared/message"
  end
    
  def clear_precompile_target
    ENV["PRECOMPILE_TARGET"] = nil
  end

  # Return the version string as a floating point number in format N.N
  def code_version(version_string)
    version_string.strip.match(/(\d.\d+)(b\d+)?(\w?)$/) and $1.to_f
  end

end
