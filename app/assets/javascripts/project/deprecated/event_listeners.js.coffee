# ===================
# = Event Listeners =
# ===================
#  A place for general event listeners. More often they are placed in the js file associated with a particular page that controls the animation for that page
$(document).ready -> 

  $(document).bind("pagebeforeload", (event) ->
    $(".display_app_state").html(display_app_state())
  )
  