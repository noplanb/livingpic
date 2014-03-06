$(document).ready -> FlashNotice.flash_off()
$(document).on "pageshow", -> FlashNotice.flash_if_necessary()

$(document).ready ->
  $("#flash").on "popupafterclose", -> FlashNotice.flash_off()

class window.FlashNotice
  
  @flash_on: false
  
  @flash: (notice, heading=false) => 
    if heading
      $("#flash .notice").show()
      $("#flash .heading").html heading
      $("#flash .notice").html notice
      $("#flash .notice").addClass "de-emphasize1"
    else
      $("#flash .notice").hide()
      $("#flash .heading").html notice
      $("#flash .notice").removeClass "de-emphasize1"
    @flash_on = true
  
  @flash_if_necessary: =>
    if @flash_on
      $("#flash").show()
      $("#flash").popup()
      $("#flash").popup("open")
  
  @flash_off: => 
    @flash_on = false
    $("#flash").hide()
    
