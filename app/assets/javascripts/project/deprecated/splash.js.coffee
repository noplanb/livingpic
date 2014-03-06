$(document).ready ->
  # If it is the first page you dont get a show event
  # if Pager.current_page is "splash"
    # $(window).unbind "resize", SplashView.setup
    # $(window).bind "resize", SplashView.setup
    # SplashView.setup()  
        
  # $("#splash").on "npb_pagebeforeshow", -> 
    # $(window).unbind "resize", SplashView.setup
    # $(window).bind "resize", SplashView.setup
    # SplashView.setup()
        
class window.SplashView
  @setup: =>
    # I do this because the background size cover doesnt work in iphone webview.
    aspect_ratio = 1.5
    width = $(window).innerWidth()
    height = Math.round(width * aspect_ratio) - 10
    # console.log height
    $(".splash_cover").css("height", "#{height}px")
    
  
    
  