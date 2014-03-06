@occasions_loaded_now_check = () =>
  if Occasion.empty()
    Logger.log("OK - user really has no occasions")
    FtuiController.show_what_next()
  else
    Logger.log("After reloading occasions, user has #{Occasion.count()} occasions")
    UserHandler.go_home()

class window.UserHandler 
  
  @init: ->
    @prefetch_assets()
    
  @startup: (opt) =>
    #  opt:
    #    - fresh = true | false :: for testing clear the appState to mimic a fresh download of the app.
    # For testing purposes /app/app?fresh=true can be used to clear the appState to mimic a fresh download of the app.
    opt ||= {}
    Logger.log("UserHandler startup with "+JSON.stringify(opt));
    if opt.fresh                 # T
      @reset()

    # always checkin regardless of whether there is a user or not, so we can have
    # tracking.  Also, if the user has been deleted, this ostensibly resets the cookie, 
    # although there could be a race condition. Unfortuately, the cookie is not visible
    # in document.cookie, so I don't know how to delete it cleanly
    # FF 2013-05-13: commenting this out because we've changed checkin to throw an error now
    @checkin()

    # If we have a user or an unknown user, just process it directly
    if current_user() || opt.unknown_user
      @go_home()
    else
      if Config.is_android() then @check_cookies() else FtuiController.show_confirm_check_cookies()
   
  @reset: ->
    clear_local_data()
    @clear_user_cookie()

  @check_cookies: =>
    Logger.log("Redirect to check cookies @ "+ Config.base_url() + "/app/check_cookies")
    app_str = if Config.is_running_on_device() then "app=true" else ""
    url = Config.base_url() + "/app/check_cookies?" + app_str
    if Config.is_android_device()
      Logger.log "Launching browser for android check_cookies"
      window.plugins.webintent.startActivity({
        action: window.plugins.webintent.ACTION_VIEW,
        url: url}, 
        -> , 
        -> Logger.log 'Failed to open URL via Android Intent'
      )
    else
      # as of cordova 2.3 have to open it via the open command
      window.open(url,'_system')
    
  # Expect to get an identifying cookie back from this
  # GARF - may not be the right place for this, but since we change hosts we need to 
  # restablish this each time for a new host
  # We checkin even if we don't have a user so that we can eliminate the cookie
  # Important: Don't use the network handler here because we could get into a funky loop
  @checkin: =>
    if NetworkHandler.network_ok() 
      Logger.log("Checking in to set up cookie with id #{current_user().id}")
      $.ajax {
        url: Config.base_url() + "/app/checkin"
        data: {id: current_user_id(), v: Config.version, p: Config.platform(), pv: Config.platform_version(), pt: push_device_token()}
        async:true
        success: (data) ->
          Logger.log "Checkin succeeded for user #{current_user().id}"
        error: (jqXHR, textStatus, errorThrown) =>
          if current_user()
            # If the user doesn't exist .... e.g. we deleted him or 
            # we switched from one server to another, we need to send the user to the 
            # registration page...
            if jqXHR.status == 410
              clear_current_user()
              @go_home()
            Logger.log("Checkin failed with error " + textStatus + ":" + errorThrown)
      }

  @clear_user_cookie: =>
    Logger.log("Clearing the user cookie")
    $.ajax({
      url: Config.base_url() + "/users/clear_user",
      async:false
      success: -> Logger.log("cleared the cookies")
      })

  # prefetch the user's assets for when he's ready
  @prefetch_assets: => 
    Logger.log("Prefetching assets")
    @safe_fetch_models()

  @safe_fetch_models: ->
    Photo.local_load_if_necessary()
    Occasion.local_load_if_necessary()
    # Prepare the photos for the current occasion for display
    if current_occasion()
      current_occasion().prepare_for_display()

  @go_home: =>
    if not NetworkHandler.check_network() then AlertHandler.display_no_network_message()
    # Now done in the boot sequence
    # @prefetch_assets() 
    if registered() 
      Logger.log("Known registered user #{current_user().id}")
      if Occasion.empty()
        # Load the occasions - then check again if they are really empty
        # This has some delay but hopefully only happens once
        Logger.log("Registered user had no occasions so loading occasions")
        Occasion.load_from_server(occasions_loaded_now_check) 
      else
        GalleryController2.show_current()
    else if current_user()
      Logger.log("Need to register user #{current_user().id}")
      # Prefetch assets to help with the registration flow.
      FtuiController.show_welcome()    
    else
      Logger.log("Need to register unknown user.")
      FtuiController.show_welcome()    
  
  # A quick hack to set the user on the app directly w/o having to go to lengths...
  @set_user: (user_id,callback=null)->
    $.ajax({
      url: Config.base_url()+"/users/set/"+user_id, 
      dataType: "json",
      async: false,
      success: (user) =>
        Logger.log("Saving current user ID "+user.id);
        set_current_user(user);
        Occasion.load_from_server(callback or @go_home)
      error: (jqXHR, textStatus, errorThrown) ->
        Logger.error("UserHandler.set_user getting user info for id #{user_id}");
    })
    
  @have_admin_access: ->
    (current_user_id() == 3 || current_user_id() == 2 ) || not Config.store_release()

  @get_sample_user: =>
    $.ajax({
      url: Config.base_url() + "/get_sample_user"
      dataType: "json"
      success: (user)->
        set_current_user(user)
      })


