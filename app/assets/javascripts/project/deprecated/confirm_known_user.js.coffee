# deprecate when FtuiController is doing all of this.
$(document).ready ->
  $("#confirm_known_user").on "pagebeforeshow", ->
    $(".current_user_fullname").html current_user_fullname() 


window.submit_name = (form_data) -> 
  name = array_to_hash(trim_all_form_data(form_data))
  if name.first_name is ""
    alert("Please enter your first name") 
    return
  
  if name.last_name is ""
    alert("Please enter your last name")  
    return
    
  # Save the edited name locally 
  cu = current_user()
  cu.first_name = name.first_name
  cu.last_name = name.last_name
  set_current_user(cu)
  
  $.mobile.changePage("#confirm_known_user")
  
  # Update the server
  # Not really necessary - the user is saved here and we'll update when
  # when we register him anyway
  $.ajax({
    url: Config.base_url() +  "/users/update",
    type: "POST",
    data: current_user()
  })

window.confirmed_name = ->
  register()
  # GARF - this is a bit budge.  I really need to have a recovery model that I'll put in later
  # for now, if the user has an occasion, then go ahead and just confirm that he's at the occasion
  if ( current_occasion() )
    $.mobile.changePage("#what_next")
  else if current_user().num_occasions > 0 
    Occasion.load_from_server(UserHandler.go_home)
  else
    $.mobile.changePage("#store_release_welcome")
  
window.register = -> 
  LoaderSpinner.show_spinner()
  $.ajax({
    url: Config.base_url() +  "/users/register",
    type: "POST",
    dataType: "json",
    async: false,
    data: $.extend(current_user(),v:Config.version)
    error: -> $.mobile.changePage("#network_error")
    success: (user) -> 
      set_current_user(user)
  })