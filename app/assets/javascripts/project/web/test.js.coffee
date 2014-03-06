$(document).ready ->
  $("#test").on "pageshow", -> Test.render()

# $(window).bind "resize", -> 
#   width =  new ThumbWidthCalculator($(window).innerWidth()).thumb_width()
#   console.log width
#   console.log $(window).innerWidth()
#   
#   $(".test_contain .masonry_item").css("width", "#{width}px")
#   $('#test .test_contain').masonry("reloadItems")
#   Test.mason()
  

class window.Test
  
  @render: =>
    @mason()
      
  @blocks: =>
    width =  new ThumbWidthCalculator($('#test .test_contain').innerWidth()).thumb_width()
    [1..10].map (n) => @block(width, n)
  
  @append_blocks: =>
    blocks = @blocks()
    $("#test .test_contain").append(blocks).masonry("reload")  
  
  @block: (width, n) =>
    el = $("<div class='masonry_item' style='margin:2px; float:left; width:#{width}px; border:1px solid red; background:#888; font-size:12px'>#{n}</div>")
    height = Math.round(Math.random()*100)
    height += 20 
    el.html("#{n} :: Height: #{height}")
    el.css("height", "#{height}px")
    el
    
  @mason: =>   
    $('#test .test_contain').masonry({
        itemSelector : '.masonry_item'
        isResizable: false
      });
      