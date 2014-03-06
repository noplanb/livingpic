$(document).bind "deviceready", ->
  if Config.is_android_device()
    $(document).on "backbutton", AndroidBackHandler.back_click
  
class window.AndroidBackHandler
  @back_click: => 
    switch Pager.current_page
      when "gallery2"
        GalleryController2.android_back()
      when "add_participants2"
        # GARF: This one doesnt work or some reason cant figure it out.
        AddParticipants2.INSTANCE.cancel()
      when "new_occasion"
        Pager.back()
      when "gallery_picker", "no_network", "network_error", "flash_notice"
        UserHandler.go_home()
    
    