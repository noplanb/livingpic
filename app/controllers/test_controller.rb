class TestController < ApplicationController
  def fail
    raise "This is a standard exception"
  end

  def pass
    render :text => "OK"
  end
  
  # Object not found
  def not_found
    User.find(-1)
  end

  def mail
    npb_mail("Sending a test mail")
    display_message_page "OK"
  end

  def sms
    npb_sms("Sending a test sms")
    display_message_page "OK"
  end

  def url
    # test the url schema for the phone
    render :text => "<a href='livingpic://?u=7'>the url</a>"
  end

  def no_user_error
    render :text => "User login required", :status => 401
  end
end

