# In this file pu js that is shared among one or more of our products:
# Our products currently are:
#   - app: packaged eventually
#   - landing: mobile web pages
#   - check_cookies: a single mobile web page.

$(document).ready (event) ->
  initialize_view()

window.initialize_view = ->
  $(".window_height").css("height", "#{$(window).height()}px")
  $(".quarter_window_height").css("height", "#{Math.floor($(window).height()/4)}px")
