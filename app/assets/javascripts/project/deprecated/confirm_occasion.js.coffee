$(document).ready ->
  $("#confirm_occasion").on("pagebeforeshow", -> 
    if current_occasion() 
      $(".current_occasion").html(current_occasion().name)
    else 
      $.mobile.changePage("#confirm_at_new_occasion")
  )


window.submit_occasion_name = (form_data) ->
  o_name = array_to_hash(trim_all_form_data(form_data))
  if o_name.name is ""
    alert("Please enter a name")
    return
  
  # occasion = new Occasion(name: o_name.name)
  occasion = Occasion.add(name: o_name.name)
  set_current_occasion( occasion )
  LoaderSpinner.show_spinner()
  occasion.save_to_server({success: occasion_saved, error: occasion_save_error})
  # Skip the population estimation for now
  # $.mobile.changePage("#estimate_population", {transition: "slide"})
  
window.occasion_saved = ->
  $.mobile.changePage("#invite")

window.occasion_save_error = ->
  $.mobile.changePage "#network_error"
