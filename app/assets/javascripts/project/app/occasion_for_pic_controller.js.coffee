$(document).ready ->
  $("#occasion_for_pic2 .auto_complete_search_input_field").on("keyup", OccasionForPicController.occasion_name_keyup)

class window.OccasionForPicController
  @page_id = "occasion_for_pic2"
  
  @show: =>
    ensure_current_occasion()
    @init_page()
    @render_page()
    @setup_auto_complete()
    Pager.change_page @page_id
      
  @setup_auto_complete: =>
    Occasion.refresh_if_needed()
   
    unless Occasion.empty()
      new AutoComplete2 {
        page_id: @page_id
        full_list: Occasion.full_list_for_auto_complete()
        fill_input_with_pick: true
        dont_use_first_letter_list:true
        show_all_on_first_letter: true
        } 
      
  @init_page: => 
    $("##{@page_id} .caption").val("")
    $("##{@page_id} .instructions").show()
    $("##{@page_id} .auto_complete_search_results_box").html ""    
    $("##{@page_id} .auto_complete_search_results_box").hide()    
    $(".last_pic_background").css("background-image","url(#{current_picture().pic})") if Config.is_running_on_device() and current_picture().pic
         
  @render_page: =>
    $("##{@page_id} .current_occasion").html(current_occasion().name)
    $("##{@page_id} .enter_name_btn_b").hide()
    if @save_to_new_occasion or Occasion.empty()
      $("##{@page_id} .auto_complete_search_input_field").first().val("")
      $("##{@page_id} .yes_current_occasion").hide()
      $("##{@page_id} .no_current_occasion").show()
      $("##{@page_id} .auto_complete_search_results_box").hide()    
    else
      $("##{@page_id} .yes_current_occasion").show()
      $("##{@page_id} .no_current_occasion").hide()
      
  @new_occasion: =>
    # Get the location for the new occasion.  This will trigger the request for the user's location
    # NOTE: this is optimistic - we're not putting in any locking mechanism yet to make sure we have
    # returned the location by the time 
    # GeoLocation.get_location() 
    return unless @set_current_occasion_from_form()
    # Handle both the same way from here...
    @existing_occasion()
    
  @existing_occasion: =>
    if current_occasion().is_new_record()
      # Note if unable to save user will be left with a network_error dialog which if closed will leave him
      # where he was before he sumbitted the form.
      @try_save_occasion_to_server()
    else
      @occasion_confirmed()
    
  @set_current_occasion_from_form: =>
    if $("##{@page_id} .auto_complete_search_input_field").first().val().trim() is ""
      alert "Please enter a name for this album." 
      return false
    
    name = $("##{@page_id} .auto_complete_search_input_field").first().val().trim()
    occasion = Occasion.find_by_name(name) or new Occasion {name:name}
    
    if occasion.is_new_record()
      return false unless confirm("Create a new album called: #{name}?")
      
    set_current_occasion( occasion )
    @save_to_new_occasion = false
    return true
    
  @try_save_occasion_to_server: =>
    LoaderSpinner.show_spinner()
    current_occasion().save_to_server({success: @new_occasion_success, error: @new_occasion_error})
    
  @new_occasion_success: (response) =>
    # Udate the id in the current_occasion
    Occasion.add(current_occasion())
    @occasion_confirmed()
        
  @new_occasion_error: (jqXHR, textStatus, errorThrown) =>
    Pager.change_page "network_error"
    
  # Start the upload and go to show the gallery
  @occasion_confirmed: =>
    Logger.log("Adding new photo to occasion "+current_occasion().id)
    @add_caption_to_picture()
    @add_local_pic_to_occasion()
    GalleryController2.show_current(true)
  
  @add_caption_to_picture: =>
    Picture.update_caption $("##{@page_id} .caption").val()
    
  @add_local_pic_to_occasion: =>
    current_occasion().new_photo(tmp_file_uri: current_picture().pic, caption: current_picture().caption, latitude: current_location().latitude, longitude: current_location().longitude, creator: current_user(), comments:[], likes:0)
            
  @occasion_name_keyup: =>
    if $("##{@page_id} .auto_complete_search_input_field").first().val().trim().length > 0
      $("##{@page_id} .instructions").hide()
    else
      $("##{@page_id} .instructions").show()
      
    @adjust_content_for_fixed_header()
            
  @adjust_content_for_fixed_header: =>
    header_height = $("##{@page_id} .fixed_header").get(0).offsetHeight - 2
    $("##{@page_id} .auto_complete_search_results_box").css("top", "#{header_height}px")
  
  @change: =>
    @save_to_new_occasion = true
    @render_page()
  
  @dont_change: =>
    @save_to_new_occasion = false
    @render_page()
  
  @cancel: => GalleryController2.show_current()
    
  
    
    
  
    
