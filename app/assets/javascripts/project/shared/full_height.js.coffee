$(document).ready -> (new FullHeight).show()
$(window).bind "resize", -> (new FullHeight).show()

class window.FullHeight
  
  constructor: ->
    @full_height_elements = $("[npb_full_height=true]")
  
  # Set the height of full_height_elements to either:
  #   - the window height 
  #   - heigh of an enclosed element with attribute npb_accomodate_height multiplied by the accomodation factor
  # whichever is greater
  show: =>
    for fh in @full_height_elements 
      do (fh) =>
        acc_height_el = $(fh).find("[npb_accomodate_height]")[0]
        acc_factor = $(acc_height_el).attr("npb_accomodate_height")

        acc_height = if acc_height_el? then Math.round($(acc_height_el).first().outerHeight() * acc_factor) else 0
        wh = $(window).innerHeight()
                
        if acc_height > wh
          $(fh).css("height", "#{acc_height}px") 
        else 
          $(fh).css("height", "#{wh}px") 
        