class window.VersionMgtView
  @render: (severity, store_link) =>
    $("#version_mgt .store_link").on "click", -> VersionMgtController.click_to_store()
    if severity is "optional"
      $("#version_mgt .optional").show()
      $("#version_mgt .mandatory").hide()
    else
      $("#version_mgt .optional").hide()
      $("#version_mgt .mandatory").show()
    Pager.change_page("version_mgt")    
    
class window.VersionMgtController
  @status: null
  
  @checkin: =>
    NetworkHandler.instance({
      url: Config.base_url() + "/app/version_mgt_checkin"
      data: {version: Config.version}
      type: "GET"
      dataType: "json"
      async: true
      retry_count: 0
      success: VersionMgtController.handle_response
    }).run()

  @handle_response: (response) => 
    sev_text = if response.out_of_date then response.out_of_date else "no"
    Logger.log "VersionMgtController: #{sev_text} update required"
    @status = response
    
  @user_skipped: => 
    Logger.log "VersionMgtController: User skipped an optional update."
    @status.user_skipped = true
    UserHandler.go_home()

  @notify_user_if_necessary: =>
   Logger.log "VersionMgtController: not notifying user because of previous skip" if @status? and  @status.user_skipped
   if @status? and @status.out_of_date? and not @status.user_skipped
     VersionMgtView.render(@status.out_of_date, @status.store_link)
     return true
   else
     return false
  
  @click_to_store: =>
    if Config.is_android_device()
      window.plugins.webintent.startActivity({
        action: window.plugins.webintent.ACTION_VIEW,
        url: @status.store_link}, 
        -> , 
        -> Logger.log 'Failed to open URL via Android Intent'
      )
    else
      window.location = @status.store_link

  @ensure_db_version_compatibility: =>
    if db_version() isnt Config.version
      Logger.log("Clearing data for db_version compatibility")
      @dom_current_occasion = null
      clear_current_occasion()
      Occasion.clear_all()
      Photo.clear_all()
      Photo.cleanup()
      set_db_version Config.version
    else
      Logger.log("No need to clear data db_version #{Config.version} is compatible.")
      
      