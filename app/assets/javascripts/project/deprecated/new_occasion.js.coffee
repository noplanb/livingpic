$(document).ready ->
  $("#new_occasion_dialog").on "pagebeforeshow",  -> 
    NewOccasionView.render()

  $("#new_occasion_dialog .new_occasion_submit").off "click"
  $("#new_occasion_dialog .new_occasion_submit").on("click", $.debounce(2000, true, NewOccasionController.post))
  

# GARF - duplicate code here with occasion_for_pic
# TODO REFACTOR!
class window.NewOccasionController
    
  @post: => @try_save_occasion_to_server() if @set_current_occasion_from_form()
    
  @set_current_occasion_from_form: =>
    id = null
    name = $("#new_occasion_dialog .new_occasion_name").val().trim()
    if name is ""
      alert "Please enter an album name." 
      return false
    GeoLocation.get_location()
    set_current_occasion new Occasion {name: name, id: id}
    return true

  @try_save_occasion_to_server: =>
    LoaderSpinner.show_spinner()
    current_occasion().save_to_server({success: @new_occasion_success, error: @new_occasion_error})

  @new_occasion_success: (response) =>
    # Udate the id in the current_occasion
    Occasion.add(current_occasion())
    @occasion_confirmed()

  @new_occasion_error: (jqXHR, textStatus, errorThrown) => $.mobile.changePage "#network_error"

  # Start the upload and go to show the gallery
  @occasion_confirmed: =>
    console.log("Created new occasion: "+current_occasion().id)
    FlashNotice.flash("Album created. Well done. Now add participants and photos.")
    @show_gallery()

  @show_gallery: => GalleryController.show(current_occasion())    
  
  
class window.NewOccasionView
  @render: => 
    $("#new_occasion_dialog .new_occasion_name").val("")
  