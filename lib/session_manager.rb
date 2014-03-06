module SessionManager

  # Some useful utility functions for handling users and sessions

  # User management convention:
  #   If a user is not logged in, we can give him the temporary ID

  private
  
  def init_user_session
    session[:footsteps] ||= Footsteps.new 
    session[:start] ||= Time.now
  end
  
  def end_user_session
    logger.mark("Removing user session for #{current_user.log_info}") if session[:user_id]
    reset_core_session_elements
    session[:footsteps] = nil
    clear_app_session_elements
  end

  def reset_user_session
    clear_app_session_elements
    reset_core_session_elements
    init_user_session
  end
  
  def current_user
    session[:user_id] ? (User.find_by_id(session[:user_id]) || reset_user_session) : nil
  end
  
  def set_current_user_id(user_id)
    session[:user_id] = user_id
  end

  def current_user_app_version
    current_user and current_user.app_version and current_user.app_version.strip.match(/(\d.\d+)$/) and $1.to_f
  end

  def set_current_user(user)
    session[:user_id] = user.id if user
  end
  alias_method :current_user=, :set_current_user
  
  def clear_current_user
    session[:user_id] = nil
  end
  
  def current_user_id
    session[:user_id] 
  end

  def set_tmp_user(user)
    user_id = User.normalize_to_id(user)
    session[:tmp_user_id] = user_id
  end
  
  def tmp_user_id
    session[:tmp_user_id]
  end
  
  def tmp_user
    session[:tmp_user_id] ? User.get_user(session[:tmp_user_id]) : nil
  end
  
  def clear_tmp_user
    session[:tmp_user_id] = nil if session[:tmp_user_id]
  end
  
  def user_logged_in?
    session[:user_id] 
  end

  # ========================
  # = Set Auth Cookies     =
  # ========================

  def auth_cookie
    cookies[:auth]
  end
  
  def auth_cookie_set?
    !cookies[:auth].blank?
  end
  
  def clear_auth_cookie
    logger.info "Removed auth cookie for #{current_user.log_info}" if (current_user)
    # I have to do this hack b/c rails doesn't automatically remove the cookie
    # if it has a domain_name set up
    cookies[:auth] = {:expires => 1.year.ago, :value => nil}
  end
  
  def set_auth_cookie(user=current_user)
    logger.info "Setting auth cookie for #{user.log_info}"
    cookies.permanent[:auth] = user.auth_token
  end

  # Set the current user, cookie him with the auth cookie, and reset his session, but only if 
  # the current user is not already set 
  def set_and_cookie_current_user(user_x)
    user = User === user_x ? user_x : User.find(user_x)
    unless user.nil? || current_user_id == user.id
      reset_user_session
      set_current_user(user)
      set_auth_cookie(user)
    end
  end
  
  # Reset the current user but don't set the auth cookie
  def reset_current_user(user_x)
    user = User === user_x ? user_x : User.find(user_x)
    unless user.nil? || current_user_id == user.id
      clear_auth_cookie
      reset_user_session
      set_current_user(user)
    end    
  end

  # ========================
  # = Manage user activity =
  # ========================
  
  # We update the last user activity, but possibly not on each activity to reduce DB writes
  def update_last_user_activity
    now = session[:last_activity] = Time.now
    return if session_is_cloned?
    if ( current_user && (session[:last_activity_saved].nil? || (now - session[:last_activity_saved] > APP_CONFIG[:save_last_activity_granularity_in_seconds].to_i ) ) ) 
      logger.info("Saved last activity date to #{now} for #{current_user.log_info}")
      current_user.update_last_activity_date
      session[:last_activity_saved] = now
    end
  end
  
  # Returning the session last user activity
  def session_last_user_activity
    session[:last_activity]
  end
  
  def user_activity_count
    session[:activity_count]
  end
  
  def update_user_activity_count
    session[:activity_count] = (session[:activity_count] || 0) + 1
  end
  
  # Returns true if there is a new session, which could happen if the 
  # session is removed from underneath by some old session sweeper
  # We do this by monitoring the last activity date, which means that
  # the application should set this value
  def session_is_new?
    session[:last_activity].nil?
  end
  
  def session_age
    session[:start] ||= Time.now
    Time.now - session[:start]
  end
  
  def session_is_cloned?
    session[:cloned]
  end
  # ========================
  # = Provide a simple interface to the session =
  # ========================
  
  def session_set(name,value)
    session[name] = value
  end
  
  def session_get(name)
    session[name]
  end
  
  def session_reset(name)
    session[name] = nil
  end
  
  # =============
  # = Log notes =
  # =============
  
  def add_log_note(note)
    session[:log_notes] ||= []
    session[:log_notes] << note
  end
  
  # Returns array of log notes
  def log_notes
    session[:log_notes]||[]
  end
  
  def clear_log_notes
    session[:log_notes] = []
  end
  
  # =============
  # = campaigns =
  # =============
  
  def set_user_acquisition_source(value)
    session[:tracking_source] = value
    logger.tmp_debug("setting tracking source to #{session[:tracking_source].inspect}")
  end
  
  def user_acquisition_source
    session[:tracking_source]
  end
  
  def clear_user_acquisition_source
    session[:tracking_source] = nil    
  end
  
  # =========================
  # = For cloning to a user =
  # =========================
  def set_cloned_user(user)
    set_current_user(user)
    session[:cloned] = true
  end
  
  private
  
  def clear_app_session_elements
    # override this in the application to clean anything that the app has set in the session that should
    # be cleared upon logout
  end
  
  def reset_core_session_elements
    # logger.tmp_info("Resetting core session elements")
    session[:user_id] = nil
    session[:cloned] = nil
    clear_user_acquisition_source
  end
    
end