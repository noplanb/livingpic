# deprecate when ftui.js is working
$(document).ready ->
  $("#what_next").on( "pagebeforeshow", (event) -> WhatNext.render_page() )
    
    
@WhatNext = {  
  render_page: =>
    if current_occasion()
      $("#what_next .current_occasion").html current_occasion().name
      $("#what_next .take_a_photo").hide()
    else
      $("#what_next .take_a_photo").show()
      $("#what_next .take_a_photo_text").html "Take a Photo"
      $("#what_next .goto_gallery").hide()
      $("#what_next .call_to_action").hide()
}
