module CookieHandling
  
  # DEPRECATED - included in SessionManager instead
  # Set the user's cookie - make it essentially permanent by setting it to 10 years
  def cookie_user
    if current_user
      cookies[:auth] = {value: current_user.auth_token, domain: site_domain, expires: Time.now + 10.years}
    end
  end
  
  # Find the user based upon the cookie
  # Returns the user object or ni
  def cookied_user
    cookies[:auth] and User.find_by_auth_token(cookies[:auth])
  end
  
  # Delete the user's cookie
  def uncookie_user
    cookies.delete :auth, :domain => site_domain
  end
  
  
end
