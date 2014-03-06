# ==============
# = Photoswipe =
# ==============
class window.PhotoswipeHandler
  @INSTANCE: null
  
  ps_instance: null
  meta_data: null
  
  # Android webview has a bug where clicks on the photoswipe layer toolbar bleed through to the gallery page even if it is 
  # set to display:none. The effect is when you click to close photoswipe you get an additional click on a picture or other
  # button that is underlying it and and you end up back in photoswipe. Here is the very cludgey work around: If there a recent
  # tool_bar_tap event we set a recent_tool_bar_tap flag here and use that to determine whether to ignore the click in the gallery. 
  recent_tool_bar_tap: false
  
  constructor: (image_list, meta_data) ->
    PhotoswipeHandler.INSTANCE = @
    
    $.error "PhotoswipeHandler you must provide a valid meta_data" unless meta_data?
    @meta_data = meta_data
    
    $.error "PhotoswipeHandler you must provide a valid image_list" unless image_list?
    @ps_instance = @create_photo_swipe_instance image_list
    
    return @ps_instance
  
  @dispose: => PhotoswipeHandler.INSTANCE = null
  
  create_photo_swipe_instance: (image_list) => 
    options = {
      getImageSource: (obj) => obj
      getImageCaption: (url) => @ps_caption_for_url(url)
      getToolbar: => @ps_toolbar
      backButtonHideEnabled: false
      captionAndToolbarFlipPosition: true
      preventSlideshow: true
      doubleTapZoomLevel: 2
      maxUserZoom: 2
      minUserZoom: 1
    }
    @ps_instance = Code.PhotoSwipe.attach(image_list, options)
    @ps_instance.addEventHandler( Code.PhotoSwipe.EventTypes.onToolbarTap, (e) => @ps_on_tool_bar_tap() )
    @ps_instance
  
  ps_on_tool_bar_tap: =>
    # See comment above re android click bug for the reason for this cludgey code.
    # console.log "recent_tap_true"
    @recent_tool_bar_tap = true
    window.setTimeout( 
      => 
        # console.log "recent_tap_false"; 
        @recent_tool_bar_tap = false
      , 1000 )
        
  ps_caption_for_url: (url) => 
    creator = @meta_data[url].creator
    "By #{creator}"

  ps_toolbar: '
    <div class="ps-toolbar-previous" style="padding-top: 12px;"></div>
    <div class="npb-ps ps-toolbar-close">
      <div class="back_btn">
        <div class="back_icon"></div>
        <span class="btn_text">All</span>
      </div>
    </div>
    <div class="ps-toolbar-next" style="padding-top: 12px;"></div>
  '
