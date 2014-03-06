# This is a simple controller that is resonsible for displaying the pages when they are updated
class window.ViewController2

  @render_on_resume: true

  @auto_render:(val=true) ->
    @render_on_resume = val
  
  @reset_refresh_icon: =>
  
  @manual_refresh: => 
    @refresh()
    
  # this method is called to refresh the current page, that is, reload the underlying object
  # from the server and then refresh it
  @refresh: =>
    # Logger.log("refreshing current page with "+@render_on_resume)
    return unless @render_on_resume

    Logger.log("ViewController refereshing the current page "+ current_page())
    if current_page() == "occasions"
      Occasion.load_from_server(@show_occasions)
    else if current_page() == "gallery"
      current_occasion().load_from_server(@show_occasion)
    else if current_page() == "pic_detail"
      PhotoView.INSTANCE.photo.load_from_server(@show_photo)
      

  @redraw: =>
    if current_page() == "occasions"
      @show_occasions()
    else if current_page() == "gallery"
      @show_occasion(current_occasion())
    else if current_page() == "pic_detail"
      @show_photo(PhotoView.INSTANCE.photo)

  @show_occasions: (success) =>
    @reset_refresh_icon()
    OccasionsView.render() if current_page() == "occasions" && success
  
  @show_occasion: (success,occasion) =>  
    @reset_refresh_icon()
    GalleryController.show(occasion,true) if current_page() == "gallery" && success

  # GARF this one is a bit hacky because by the time the request comes back you could 
  # be on a different photo. we really should be checking that we're on the same photo
  @show_photo: (photo) =>
    @reset_refresh_icon()
    Carousel.render_pic_detail_page(photo) if current_page() == "pic_detail"

  # When the status of a photo changes, you can 
  # call this to update the view, if there is one
  @photo_updated: (photo) =>
    if current_page() == "gallery" && current_occasion_id() == photo.occasion_id
      # Update the display of the photo in the gallery
      Logger.log("ViewController updating photo in gallery")
      GalleryView.update_photo(photo)
