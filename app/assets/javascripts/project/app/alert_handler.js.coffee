class window.AlertHandler 
  @message_displayed: null
  @should_display_no_network_message: ->
    # display the message if we haven't shown it in several hours = 4 (hours) *3600 (seconds/hour) *1000 milliseconds
    @message_displayed == null || ((new Date).getTime() - @message_displayed) > 4*3600*1000

  @display_no_network_message: ->
    if @should_display_no_network_message()
      @message_displayed = (new Date).getTime()
      @message("No internet connection.  You may not see all albums or create new ones.")
      # Pager.change_page("no_network")
      return true
    else
      return false

  @message: (message)->
    alert(message)