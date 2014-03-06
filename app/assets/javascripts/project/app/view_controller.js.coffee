class window.ViewController

  @render_on_resume: true

  @auto_render: (val=true) ->
    @render_on_resume = val
  
  # this method is called to refresh the current page, that is, reload the underlying object
  # from the server and then refresh it
  @refresh: =>      
    return unless @render_on_resume

    Logger.log("ViewController refereshing the current page "+ current_page())
    if current_page() == "occasions2"
      Occasion.load_from_server(@show_occasions)
    else if current_page() == "gallery2"
      current_occasion().load_from_server(@show_occasion)      

  @redraw: =>
    if current_page() == "occasions2"
      @show_occasions()
    else if current_page() == "gallery2"
      @show_occasion(current_occasion())

  @show_occasions: (success) =>
    OccasionsController.show() if current_page() == "occasions2" && success
  
  @show_occasion: (status,occasion) =>  
    GalleryController2.show(occasion,true) if current_page() == "gallery2" && status != Occasion.STATUS.ERROR

