class window.Refresher
  
  constructor: (options={}) ->
    
    $.error "Refresher requires a do_refresh function" unless typeof options.do_refresh is "function"
    @do_refresh = options.do_refresh
        
    $.error "Refresher requires a refresh_div" unless options.refresh_div
    @refresh_div = options.refresh_div
    @refresh_text = @refresh_div.find(".text")
    @refresh_icon = @refresh_div.find(".icon")
    
    @bottom_of_refresh_div = @refresh_div.position().top + @refresh_div.get(0).offsetHeight
    @top_of_refresh_message = @bottom_of_refresh_div - @refresh_icon.get(0).offsetHeight
    
    @set_message("pull")
  
  move_px: (current_position) =>
    @set_message "release" if current_position < @top_of_refresh_message - 15
    
  move_end: =>
    switch @current_message
      when "pull"
        return false
      when "release"
        @set_message("refreshing")
        @do_refresh()
        return @top_of_refresh_message - 20
  
  unchanged: => @set_message("unchanged")
  
  changed: => @set_message("changed")

  error: => @set_message("error")
  
  refresh_done: => @set_message("pull")
    
  set_message: (type) =>
    return if @current_message is type
    switch type
      when "pull"
        @refresh_text.html "Pull down to refresh"
        @refresh_icon.removeClass()
        @refresh_icon.addClass "icon"
      when "release" 
        @refresh_text.html "Release to refresh"
        @refresh_icon.removeClass()
        @refresh_icon.addClass "icon icon_up_arrow"
      when "refreshing" 
        @refresh_text.html "Checking for new photos"
        @refresh_icon.removeClass()
        @refresh_icon.addClass "icon icon_circle_arrow"
        @refresh_icon.addClass "spin_animate" unless Config.is_android_device() # Too much for android's puny brain.
      when "unchanged"
        @refresh_text.html "Nothing new"
        @refresh_icon.removeClass()
        @refresh_icon.addClass "icon"
      when "changed"
        @refresh_text.html "New Stuff!"
        @refresh_icon.removeClass()
        @refresh_icon.addClass "icon"
      when "error"
        @refresh_text.html "Can't reach LivingPic"
        @refresh_icon.removeClass()
        @refresh_icon.addClass "icon"
    @current_message = type
    
  
  