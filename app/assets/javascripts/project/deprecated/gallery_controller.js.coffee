# Deprecate when gallery_view2 is working and handles this.
class window.GalleryController
  
  @show: (occasion,refresh=false) => 
    # This could get called when there are no occasions, or the occasion list is incomplete
    # Try to load the occasions list if need be
    # console.log("GalleryController.show occasion = "+JSON.stringify(occasion))
    
    # We stick notify the user about an app version out of date here.
    return if VersionMgtController.notify_user_if_necessary()
        
    if not occasion? then occasion = current_occasion() 

    if typeof occasion is "object"
      occasion_id = parseInt(occasion.id)
    else
      occasion_id = parseInt(occasion)

    console.log("GalleryController.show occasion_id = "+occasion_id)
    if occasion_id
      # Not sure this is the right thing to do because browsing a gallery should not change 
      # where you are going to add photos, but the add participants code 
      # uses the global current_occasion and I don't feel like refactoring it to 
      # fix this.  One reason to minimize the use of globals.... 
      occasion = Occasion.find(occasion_id)
      # occasion.prepare_for_display()  #GARF: Sani removed for testing to see if it speeds up the display of large galleries
      if occasion != current_occasion()
        set_current_occasion occasion
        # occasion.prepare_for_display() #GARF: Sani removed for testing to see if it speeds up the display of large galleries
        
      GalleryView.render(occasion,refresh)
    else
      # GARF - this is not really the right thing to do, but if we don't have the occasions
      # we need to show some gallery, else the occasions list
      # Thought that just going to the occasions page would be safer at this point for now because of recursive nature calling go to last gallery here. -s
      # @go_to_last_gallery()
      $.mobile.changePage("#occasions")
        
        
  @show_current: => @show(current_occasion())
  
