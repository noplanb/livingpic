$(document).ready -> 
  LandingView.show()
  $("#landing .unsubscribe").on "click", -> LandingView.unsubscribe()
  $("#landing .resubscribe").on "click", -> LandingView.resubscribe()
  
class window.LandingView
        
  @show: => 
    $("#landing .unsubscribed").hide()
    
  @unsubscribe: => 
    $("#landing .unsubscribed").show()
    $("#landing .unsubscribe").hide()
    @notify_server("unsubscribe")

  @resubscribe: => 
    $("#landing .unsubscribed").hide()
    $("#landing .unsubscribe").show()
    @notify_server("subscribe")
  
  @notify_server: (action) =>
    $.ajax {
      url: "/users/#{action}_sms"; 
    }