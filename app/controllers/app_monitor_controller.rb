# This controller is used to monitor the app's status
# e.g. 
#  - errors thrown
#  - events of note
#  - pages viewed 
# It writes everything to a log of the format
# Date: [user_id] event_type: content=<main content from info>, <other params in app_info as name value pairs>

class AppMonitorController < ApplicationController

  include AppEventLogging
  include NoPlanB::Helpers::DisplayFormatHelper

  protect_from_forgery :except => [:log]

  # Log an app errors
  # INPUT:
  #  - message
  #  - state
  def log
    app_params = params[:app_info].symbolize_keys
    user_id = app_params[:user_id] && app_params.delete(:user_id)    
    params_string = app_params.keys.sort.map { |k| "#{k}=#{app_params[k]}" }.join(",")
    session_id = session["session_id"]
    value = params[:value]
    if ["ping_error","network_error"].include? params[:type]
      start= Time.at(value[0].to_i/1000.0).strftime("%x %X") 
      if value.length > 1
        duration = format_seconds_duration (value[1].to_i - value[0].to_i)/1000.0
        value = "at #{start} for #{duration} "
      else
        value = "at #{start}"
      end
    elsif ["hung_error","server_error"].include? params[:type]
      JSON.parse(params[:value]).map do |url,time|
        time = Time.at(time.to_i/1000.0).strftime("%x %X") 
        value = "#{url} on #{time}"
      end.join(",")
    elsif params[:type] == "javascript_error"
      npb_mail("Javascript error: User #{user_id}; error #{value}")
    end
    log_app_event "[#{user_id || tmp_user_id}] #{params[:type]}=#{value}, #{params_string}, session_id=#{session_id}"
    render :text => "OK"    
  end

end
