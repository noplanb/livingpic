@EmailRegistration = {
  
  submit_registration: =>
    if (name = $("#register .name").first().val().trim()) is ""
      alert "Please enter your name." 
      return false
    
    unless (email = $("#register .email").first().val().trim()).is_email()
      alert "Please enter a valid email." 
      return false
    
    if (password = $("#register .password").first().val().trim()) is ""
      alert "Please create a password." 
      return false
        
    $.ajax {
      url: Config.base_url() + "/users/register_with_password"
      type: "post"
      data: { user: {first_name:name, email:email, password:password}, v: Config.version}
      success: (r) -> 
        if r.success
          set_current_user(r.success.user)
          set_registered()
          UserHandler.startup()
        else
          alert("There is already and account with email: #{email}. Please login.")
          $("#login .email").val(email)
          $.mobile.changePage("#login")
    }
    
  submit_login: =>
    unless (email = $("#login .email").first().val().trim()).is_email()
      alert "Please enter a valid email." 
      return false
    
    if (password = $("#login .password").first().val().trim()) is ""
      alert "Please enter your password." 
      return false
    
    $.ajax {
      url: Config.base_url() + "/users/login_with_password"
      type: "post"
      data: user: {email:email, password:password}
      success: (r) -> 
        if r.success
          set_current_user(r.success.user)
          set_registered()
          UserHandler.startup()
        else
          alert("Email or password is incorrect please try again.")
    }
    
}
  
  