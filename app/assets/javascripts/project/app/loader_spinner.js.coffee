# Usage:
# For any link or button that will need to go the server and block the user add the classname: "show_spinner"
# The spinner should automatically be removed before show for any page change. Note you cant use the html
# onclick for action you want for the button or link. You need to create an event handler for it.

$(document).on "pagebeforeshow", -> LoaderSpinner.hide_spinner()
$(document).on "npb_pagebeforeshow", -> LoaderSpinner.hide_spinner()

class window.LoaderSpinner
        
  @show_spinner: => $("#fullpage_loader_spinner").show()    
    
  @hide_spinner: => $("#fullpage_loader_spinner").hide()
      
  @blank_page_spinner: =>
    Pager.change_page("blank_page")
    @show_spinner()
    
     
  