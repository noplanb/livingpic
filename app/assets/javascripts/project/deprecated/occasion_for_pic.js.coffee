# Deprecate when occasion_for_pic_controller.js is working.
$(document).ready ->
  $("#occasion_for_pic").on "pagebeforeshow", (event) -> 
    ensure_current_occasion()
    new OccasionForPic
  $("#occasion_for_pic .auto_complete_search_input_field").keyup -> OccasionForPic.INSTANCE.occasion_name_keyup()
  
  
class window.OccasionForPic 
  
  @INSTANCE: null
  
  constructor: ->
    OccasionForPic.INSTANCE = @
    $("#occasion_for_pic .caption").val("")
    $(".last_pic_background").css("background-image","url(#{current_picture().pic})") if Config.is_running_on_device() and current_picture().pic?
    # There should be an occasions instance since we should call it as part of boot and it is called after photo create is done as well.
    Occasion.refresh_if_needed()
    # Make sure there isn't an autocomplete from some other task hanging around.
    AutoComplete.dispose()
    unless Occasion.empty()
      new AutoComplete {
        page_id: "occasion_for_pic"
        full_list: Occasion.full_list_for_auto_complete()
        fill_input_with_pick: true
        dont_use_first_letter_list:true
        show_all_on_first_letter: true
        } 
    OccasionForPic.setup_click_handlers()    
    @render_page()
  
  @setup_click_handlers: =>
    $("#occasion_for_pic .save_in_current_occasion_button").unbind "click"
    $("#occasion_for_pic .save_in_current_occasion_button").on "click", $.debounce(2000, true, OccasionForPic.INSTANCE.existing_occasion)
    
    $("#occasion_for_pic .search_block .done_button").unbind "click"
    $("#occasion_for_pic .search_block .done_button").on "click", $.debounce(2000, true, OccasionForPic.INSTANCE.new_occasion)
    
        
  render_page: =>
    $("#occasion_for_pic .current_occasion").html(current_occasion().name)
    $("#occasion_for_pic .enter_name_btn_b").hide()
    if @save_to_new_occasion or Occasion.empty()
      $("#occasion_for_pic .auto_complete_search_input_field").first().val("")
      $("#occasion_for_pic .yes_current_occasion").hide()
      $("#occasion_for_pic .no_current_occasion").show()
    else
      $("#occasion_for_pic .yes_current_occasion").show()
      $("#occasion_for_pic .no_current_occasion").hide()
      
  new_occasion: =>
    # Get the location for the new occasion.  This will trigger the request for the user's location
    # NOTE: this is optimistic - we're not putting in any locking mechanism yet to make sure we have
    # returned the location by the time 
    # GeoLocation.get_location() 
    return unless @set_current_occasion_from_form()
    # Handle both the same way from here...
    @existing_occasion()
    
  existing_occasion: =>
    if current_occasion().is_new_record()
      # Note if unable to save user will be left with a network_error dialog which if closed will leave him
      # where he was before he sumbitted the form.
      @try_save_occasion_to_server()
    else
      @occasion_confirmed()
    
  set_current_occasion_from_form: =>
    if $("#occasion_for_pic .auto_complete_search_input_field").first().val().trim() is ""
      alert "Please enter a name for this occasion." 
      return false
    
    # Garf: There is probably a bug here if a user picks an occasion from autocomplete then edits it in the
    # search window it will save the picked name rather than the edited name.
    if AutoComplete.INSTANCE? and AutoComplete.INSTANCE.picked_ids().length > 0
      id = AutoComplete.INSTANCE.picked_ids()[0]
      name = AutoComplete.INSTANCE.picked_items()[id]
    else
      name = $("#occasion_for_pic .auto_complete_search_input_field").first().val().trim()
      id = null
    
    set_current_occasion( Occasion.find(id) || new Occasion {name: name, id: id} )
    @save_to_new_occasion = false
    return true
    
  try_save_occasion_to_server: =>
    LoaderSpinner.show_spinner()
    current_occasion().save_to_server({success: @new_occasion_success, error: @new_occasion_error})
    
  new_occasion_success: (response) =>
    # Udate the id in the current_occasion
    Occasion.add(current_occasion())
    @occasion_confirmed()
        
  new_occasion_error: (jqXHR, textStatus, errorThrown) =>
    $.mobile.changePage "#network_error"
    
  # Start the upload and go to show the gallery
  occasion_confirmed: =>
    Logger.log("Adding new photo to occasion "+current_occasion().id)
    @add_caption_to_picture()
    @add_local_pic_to_occasion()
    @show_gallery()
  
  add_caption_to_picture: =>
    Picture.update_caption Photo.clean_caption($("#occasion_for_pic .caption").val())
    
  add_local_pic_to_occasion: =>
    current_occasion().new_photo(tmp_file_uri: current_picture().pic, caption: current_picture().caption, latitude: current_location().latitude, longitude: current_location().longitude, creator: current_user(), comments:[], likes:0)
  
  show_gallery: =>    
    GalleryController.show(current_occasion())    
          
  occasion_name_keyup: =>
    if $("#occasion_for_pic .auto_complete_search_input_field").first().val().trim().length > 0
      $("#occasion_for_pic .instructions").hide()
      $("#occasion_for_pic .ui-footer").hide()
      
    else
      $("#occasion_for_pic .instructions").show()
      $("#occasion_for_pic .ui-footer").show()
      
    @adjust_content_for_fixed_header()
            
  adjust_content_for_fixed_header: =>
    header_height = $("#occasion_for_pic .fixed_header").height()
    $("#occasion_for_pic .content_under_fixed_header").css("top", "#{header_height}px")
  
  change: =>
    @save_to_new_occasion = true
    @render_page()
  
  dont_change: =>
    @save_to_new_occasion = false
    @render_page()
  
  cancel: =>
    FlashNotice.flash("No photo added")
    GalleryController.show(current_occasion())
    
  
    
    
  
    
    