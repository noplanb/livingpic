class window.FtuiController
  @show_welcome: => 
    $("#welcome2 .first_name").html current_user().first_name if current_user() and current_user().first_name
    Pager.change_page("welcome2")
  
  @show_confirm_check_cookies: => Pager.change_page "confirm_check_cookies2"
  
  @check_cookies: => 
    Pager.change_page 'splash' 
    UserHandler.check_cookies()
  
  @dont_check_cookies: => UserHandler.startup  unknown_user:true 
  
  @set_me_up: => if current_user() then @show_confirm_known_user() else @show_unknown_user()
    
  @show_unknown_user: => 
    new PhoneEntryFieldController("unknown_user_phone")
    Pager.change_page("unknown_user2")
  
  @show_confirm_known_user: =>
    $(".current_user_fullname").html current_user_fullname() 
    Pager.change_page "confirm_known_user2"
  
  @show_edit_name: => 
    $("#edit_name2 .edit_first_name").val current_user().first_name
    $("#edit_name2 .edit_last_name").val current_user().last_name
    Pager.change_page "edit_name2"
  
  @submit_new_user_name_and_phone: (form_data) => 
    user = array_to_hash(trim_all_form_data(form_data))
    user.mobile_number = user.mobile_number.trim_phone()
    return unless @validate_name user
    return unless @validate_phone user

    set_current_user(user)
    @confirmed_name()  
  
  @submit_name = (form_data) -> 
    user = array_to_hash(trim_all_form_data(form_data))
    return unless @validate_name user

    # Save the edited name locally 
    cu = current_user()
    cu.first_name = user.first_name
    cu.last_name = user.last_name
    set_current_user(cu)

    @show_confirm_known_user()

    # Update the server
    # Not really necessary - the user is saved here and we'll update when
    # when we register him anyway
    $.ajax({
      url: Config.base_url() +  "/users/update",
      type: "POST",
      data: current_user()
    })
  
  @validate_name: (user) =>
    if user.first_name is ""
      alert("Please enter your first name") 
      return false

    if user.last_name is ""
      alert("Please enter your last name")  
      return false
    
    return true
  
  @validate_phone: (user) =>
    unless user.mobile_number.is_phone()
      alert("Please select country and enter your mobile number with area code.")  
      return false
    return true
    
  @confirmed_name: =>
    @register(@register_done)
  
  @register_done: (status) =>
    return if status is false
    
    # GARF - this is a bit budge.  I really need to have a recovery model that I'll put in later
    # for now, if the user has an occasion, then go ahead and just confirm that he's at the occasion
    if not current_occasion() and current_user().num_occasions > 0 
      Occasion.load_from_server(UserHandler.go_home)
    else
      @show_what_next()
    
  @register: (callback = ->) => 
    Debug.log "register user"
    LoaderSpinner.show_spinner()
    $.ajax({
      url: Config.base_url() +  "/users/register",
      type: "POST",
      dataType: "json",
      async: false,
      data: $.extend(current_user(),v:Config.version)
      error: -> 
        Pager.change_page("network_error")
        callback(false)
      success: (user) -> 
        set_current_user(user)
        callback(true)
        # Set up the new user with push notifiation capability
        PushHandler.init()
    })

  @show_what_next: =>
    if current_occasion()
      $("#what_next2 .current_occasion").html current_occasion().name
      $("#what_next2 .yes_current_occasion").show()
      $("#what_next2 .no_current_occasion").hide()
    else
      $("#what_next2 .yes_current_occasion").hide()
      $("#what_next2 .no_current_occasion").show()
    Pager.change_page "what_next2"
