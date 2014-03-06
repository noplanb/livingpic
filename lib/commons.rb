module Commons

  include NoPlanB::MyIp
  
  private
  
  def store_link
    if is_iphone? 
      APP_CONFIG[:iphone_store_link]
    else
      APP_CONFIG[:android_store_link]
    end
  end
  
  def dev_mode?
    Rails.env == "development"
  end  
  
  def site_name
    APP_CONFIG[:site_name]
  end

  def domain_name
    dev_mode? ? defined?(request) ? request.base_url : "localhost:3000" : APP_CONFIG[:domain_name] 
  end


end