# This method is called whenever the app is launched on iphone. Needs to be explicitly called on android.
# We save the launch URL so that it can be launched after boot initialization
window.handleOpenURL = (url) -> 
  Logger.log("handleOpenURL called with url "+url)
  window.handle_launch_directive MessageHandler.get_launch_directive_from_url(url);
   
window.launch_directive = null

window.handle_launch_directive = (directive) ->
  if @Boot.booted
    MessageHandler.handle_launch_directive(directive) 
  else
    Logger.log("Setting launch directive: "+JSON.stringify(directive))
    window.launch_directive = directive
 
# Handle the boot up for for both cases running on a device and running in a browser
$(document).ready ->
  
  # Allows jqm to not enhance pages where data-enhance="false"
  $(document).on "mobileinit", -> $.mobile.ignoreContentEnabled = true
  
  window.onerror = (message, url, line_num) ->
    return true unless Config.store_release()
    Logger.error("Javascript error #{message} on line #{line_num}")
    if UserHandler.have_admin_access()
      alert("javascript error line #{line_num}: #{message}")
    else
      EventHandler.log_to_server({type: "javascript_error", value: "url #{url} line #{line_num}: #{message}"}) 
    return true

  Logger.init()
  Config.init()
  if Config.is_running_on_device()
    $(document).on "deviceready", ->
      Logger.log("")
      Logger.log("--------------------------")
      Logger.log("Device is ready")

      VersionMgtController.checkin()
      VersionMgtController.ensure_db_version_compatibility()
      Config.print()
      Boot.initialize()
      # For iphone the framework already calles handleOpenURL() every time the app starts
      # for android we have to tell it to do that
      if  Config.is_android_device()
        # Note the MessageHandler will call UserHandler startup as necessary for android.
        window.plugins.webintent.getUri (uri) -> 
          Logger.log "Android: webintent.getUri got: #{uri}"
          window.handleOpenURL(uri)
        # Important!! This has to run after the webintent plugin else it messes with it!
        PushHandler.init()
      else
        # On iphone if I init the push hander after the launch directive I don't get the notification set until the launch directive
        # has been set
        PushHandler.init()
        MessageHandler.handle_launch_directive(window.launch_directive) 
        window.launch_directive = null


    $(document).on "pause", ->
      # Note that when the app is paused you can't Logger.log or alert or anything
      NetworkHandler.save_instances()
      ViewController.auto_render(true)

    $(document).on "resume", ->
      Logger.log("")
      Logger.log("--------------------------")
      # Warning - don't change this Logger.log wording - logger keys off of it....
      Logger.log("System resumed")

      # The problem with running initialize and checkin on resume is that something as simple as coming back from the camera
      # causes a resume. You dont want to wait to checkin and check_connectivity when coming back from the camera.
      # Hopefully the app in the background will have been going through its init from when device_ready first fired and there 
      # is no need to initialize or checkin. Leaving this comment here until we are certain that my logic is not crap.
      # UserHandler.checkin()
      
      # Running boot.initialize for a couple of reasons:
      # 1) refresh the location
      # 2) check connectivity and restart an upload if needed
      Boot.initialize()
      
      # Corner case where registration failed and the user paused then resumed the app.
      if not registered()
        UserHandler.go_home()
        return
        
      # Let's refresh the current page on a resume unless we had a launch directive
      if  Config.is_android_device()
        ViewController.refresh()
      else
        # Call the message handler because a redirect back from the check_cookies is a resume event
        # for the iphone.  
        if window.launch_directive
          MessageHandler.handle_launch_directive(window.launch_directive) 
          window.launch_directive = null
        else
          # This will refresh only if something else hadn't already rendered
          ViewController.refresh() 
          
      if not current_page() or current_page() is "splash"
        UserHandler.go_home()

  else
    # Create a dummy device 
      Boot.mock_device()
      Boot.initialize()
      # This will invoke startup if necessary
      MessageHandler.handle_message(window.location.href) 

@Boot = {
  booted: null

  initialize:  -> 
    @booted = false
    Logger.log("Booting....")
    GeoLocation.get_location() 
    if Config.is_android_device()
      Contacts.prefetch({fresh:true})
    else
      Contacts.refresh_if_allowed()
    NetworkHandler.init()
    Filer.init()
    Photo.init()
    PushHandler.reset_icon()
    AlbumController.init()
    NetworkHandler.check_connectivity()
    UserHandler.init()
    @booted = true
    Logger.log("Booting done")
        
  mock_device: ->
    Logger.log("Mocking device characteristics")
    unless navigator.connection
      $.extend(navigator,{connection: {type: "wifi"}})

 }