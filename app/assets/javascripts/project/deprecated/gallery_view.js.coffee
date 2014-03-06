# ===================
# = Page hide event =
# ===================  
$(document).ready ->
  $("#gallery").on "pagehide", (event, data) -> 
    $("#gallery .pics").css("visibility", "hidden") # To prevent photos stacking on the left being shown before masonry sets them up.
    unless data.nextPage.attr("id") is "pic_detail"
      GalleryHandler.INSTANCE.dispose() if GalleryHandler.INSTANCE? 
    
  # $#gallery needs to be displayed before we call update_gallery_page or masonry wont work. I tried explicity doing 
  # $#gallery.show in gallery handler but that breaks jquery_mobile when it tries to go to other pages later.
  # So I am setting this event handler to trigger after we are sure that $#gallery is shown.
  $("#gallery").on "pageshow", ->
      occasion = GalleryView.occasion
      occasion_id = GalleryView.occasion.id

      new GalleryHandler(occasion)

      GalleryHandler.INSTANCE.update_gallery_page()

# ===============
# = GalleryView =
# ===============
class window.GalleryView

  @render: (occasion, refresh=false) =>    
    Logger.log("Rendering occasion #{occasion.id} with refresh = #{refresh} and current_page = "+current_page())
    GalleryView.occasion = occasion
    occasion_id = occasion.id
    
    GalleryHeadView.render(occasion)
    ParticipantsView.render(occasion)
    AddPhotosBannerView.render()
    
    # I put changePage at the end here because the event handler below should not be allowed to fire until
    # everything is ready to display the gallery. Note this is a bit of a bummer because if safe_fetch blocks for some
    # time above then the click to show gallery will feel sluggish.
    if (current_page() is "gallery") && refresh
      new GalleryHandler(occasion)
      GalleryHandler.INSTANCE.update_gallery_page()
    else
      $.mobile.changePage("#gallery")

  @update_photo: (photo) ->
    GalleryHandler.INSTANCE.update_thumb_status(photo) if GalleryHandler.INSTANCE

# =======================
# = AddPhotosBannerView =
# =======================
class window.AddPhotosBannerView
  @render: => 
    $("#gallery .add_photos_banner .first_name").html current_user() and current_user().first_name
    if current_occasion().num_photos_by_current_user() >= 2
      $("#gallery .add_photos_banner").hide() 
    else
      $("#gallery .add_photos_banner").show() 
        
# ===================
# = GalleryHeadView =
# ===================
class window.GalleryHeadView
  @render: (occasion) =>
    $("#gallery .occasion_name").html(occasion.name)
    $("#gallery .occasion_city").html(occasion.city)
    $("#gallery .occasion_date").html(lp_date_format occasion.start_time)
  

# ==================
# = GalleryHandler =
# ==================
class window.GalleryHandler
  # Class Constants  
  # With FIRST_BATCH_SIZE=20 and BATCH_SIZE=50 on Evas galaxy it takes roughly 1sec to load first 20 through initialzing 
  # MasonryHandler and it takes roughly .8 sec for each 50 appended thereafter.
  @FIRST_BATCH_SIZE: 20
  @BATCH_SIZE: 50
  @NEXT_BATCH_LOAD_THRESHOLD: 30
  @BATCH_LOAD_DELAY: 50
  
  # Class Enum
  @STATUS = {
    NOT_SET_TO_LOAD: 0,
    SET_TO_LOAD : 1,
    LOADED : 2
  }
  
  # Class Methods
  @INSTANCE: null
  @large_image_url: (thumb_url) => Config.full_url(thumb_url.replace(/thumb/, "phone"))    
  
  constructor: (occasion, options={}) -> 
    # Dispose in case we are on the gallery page already but want to update anyway as in resume.
    GalleryHandler.INSTANCE.dispose() if GalleryHandler.INSTANCE? 
    
    GalleryHandler.INSTANCE = @
    
    @gallery_box = if options.gallery_box? then options.gallery_box else $("#gallery .pics")
        
    unless occasion?
      $.error "GalleryHandler requires an occasion object"
    @occasion = occasion
    
    image_list = occasion.photos
    @image_list = []

    # @ps_meta_data = {}
    for pic, i in image_list
      do => 
        @image_list.push $.extend(pic,{draw_id: pic.id,i: i, load_status: GalleryHandler.STATUS.NOT_SET_TO_LOAD})
        # @ps_meta_data[GalleryHandler.large_image_url(pic.url)] = i: pic.i, creator: pic.creator
    
    # Aggregate tracking variables
    @num_images = @image_list.length
    @num_loaded = 0
    @num_set_to_load = 0
    @num_left_to_load = @num_images
    @next_batch_num = 0
    
    # @large_image_list = @image_list.map (obj) -> GalleryHandler.large_image_url(obj.url)
            
    # @photo_swipe = new PhotoswipeHandler(@large_image_list, @ps_meta_data) unless @num_images is 0
     
    @FIRST_BATCH_SIZE = if options.first_batch_size? then options.first_batch_size else GalleryHandler.FIRST_BATCH_SIZE
    @thumb_width = (new ThumbWidthCalculator).thumb_width()
      
    # Interval timer
    @delay = null
  
  # Find the image information by ID
  find_by_id: (id) => 
    id = parseInt(id)
    found = null
    for image in @image_list
      if image.id == id || image.draw_id == id
        found = image
        break
    found

  next_img: (img) =>
    i = img.i
    if i >= @image_list.length - 1 then @image_list.first() else @image_list[i+1]
    
  prev_img: (img) =>
    i = img.i
    if i <= 0 then @image_list.last() else @image_list[i-1]
    
    
  # Return the next batch to load based on some rules.
  next_batch_to_load: => 
    @next_batch_num++
    if @next_batch_num is 1
      return @image_list_not_set_to_load()[0..@FIRST_BATCH_SIZE-1] 
    else 
      return @image_list_not_set_to_load()[0..GalleryHandler.BATCH_SIZE-1] 
  
  # Return the full list images that have yet to be set_to_load
  image_list_not_set_to_load: => 
    ret_val = @image_list.filter (img) => img.load_status is GalleryHandler.STATUS.NOT_SET_TO_LOAD
    ret_val
    
  num_set_to_load_or_loaded: => 
    @num_set_to_load + @num_loaded
    
  load_batch: (batch) => 
    NPBTimer.start()
    NPBTimer.print "Start load batch #{batch.length}"
    thumbs = batch.map (img) => @thumb_box_for_img(img)
    NPBTimer.print "Done map thumbs"
    @gallery_box.append(thumbs)    
    NPBTimer.print "Done append thumbs"    
    if @is_on_first_batch()
      MasonryHandler.initialize(@gallery_box, ".thumb_box") 
      NPBTimer.print "Done Masonry handler intialized"
    else
     flat_thumbs = thumbs.map (th) => th.get(0)
     @gallery_box.masonry('appended', $(flat_thumbs))
     NPBTimer.print "Done masonry_appended"
    
    @mark_img_loaded(img) for img in batch
  
  is_on_first_batch: => 
    @next_batch_num is 1 
     
  mark_img_loaded: (img) => 
    @image_list[img.i].load_status = GalleryHandler.STATUS.SET_TO_LOAD
    @num_set_to_load++
    @num_left_to_load--
    
  thumb_box_for_img: (img) => 
    thumb_box = $("<div id=#{img.draw_id} class='thumb_box ui-button-up-a' data-index=#{img.i} style='float:left; width:#{@thumb_width}px'/>")
    
    img_tag = $("<img src='' data-index=#{img.i}  style='width:#{@thumb_width}px; height:#{@thumb_height(img)}'/>")
    img_tag.bind "load", @on_img_load
    thumb_box.append img_tag
    
    caption = $("<div class='caption'>#{img.caption}</div>")
    thumb_box.append caption unless img.caption is "" or !img.caption?
    
    author = $("<div class='thumb_author'><span class='de-emphasize1'>By</span> <span class='de-emphasize2'>#{img.creator.first_name} #{img.creator.last_name}</span></div>")
    thumb_box.append author
    
    comments_likes = new CommentsLikesStatsView(img)
    thumb_box.append $("<div class='comments_likes'></div>").html(comments_likes.html())
    
    comments = new CommentsView(img, true)
    thumb_box.append comments.comments_html(3)

    thumb_box.bind "click", @on_img_click
    thumb_box.find("img").attr("src", Config.full_url(img.thumb_display_url()))
    # Note I use the replace text above rather than the change attr below because the change attr below causes a desktop safari
    # as well as mobile android and mobile safari to reload the page for some reason. 
    # el.attr( "src", img )
    thumb_box
  
  update_thumb_status: (photo) =>
    Logger.log("Updating thumbnail photo status for "+photo.id)
    if likes_bin = $("##{photo.draw_id} .comments_likes")
      comments_likes = new CommentsLikesStatsView(photo)
      likes_bin.html(comments_likes.html())

  thumb_height: (img) => 
    return "auto" if LpUrl.is_local(img.url)
    if img.aspect_ratio? then Math.round(@thumb_width/img.aspect_ratio)+"px" else "auto"
    
  on_img_load: (event) => 
    @image_list[$(event.target).data("index")].load_status = GalleryHandler.STATUS.LOADED
    @num_loaded++
    @num_set_to_load--
    # I put the adjust_thumb_width() here because after enough images are loaded a scroll bar appears which affects the window size but
    # does not cause a resize event to trigger. By putting it here I reapply the adjust_thumb_width() hopefully when enough images (9) have appeard
    # to cause a scroll bar on iphone and android and at least once when all the images have loaded.
    # 5/28/2013 commented out the line below since it appears not to be necessary while using masonry and it is very expensive as it cuases 
    # masonry to reload.
    # @adjust_thumb_width() if @num_loaded is 9 or @num_set_to_load is 0
  
  on_img_click: (event) =>
    # Due to android click on hidden elements bug. See comment in PhotoswipeHandler details on this cludge.
    # Removed photoswipe for now to enable photo detail page with comments
    # return if PhotoswipeHandler.INSTANCE.recent_tool_bar_tap
    # index = $(event.target).data("index")
    # @photo_swipe.show(index)

    e = $(event.target).closest(".thumb_box")[0]
    photo = GalleryHandler.INSTANCE.find_by_id(e.id)
    Carousel.display_photo(photo)
    
  next_batch_load_threshold_achieved: =>
    # @loaded_percentage() > GalleryHandler.NEXT_BATCH_LOAD_THRESHOLD
    if @next_batch_num is 1
      return true
    else if @num_set_to_load < ( GalleryHandler.NEXT_BATCH_LOAD_THRESHOLD * @next_batch_num )
      return true
    else 
      false
  
  loaded_percentage: =>
    (1.0 * @num_loaded) / (@num_set_to_load + @num_loaded)
  
  update_gallery_page: =>
    if @num_images is 0
      @display_empty_gallery()
    else
      @bind_img_size_handler()
      @display_gallery()
    
  display_empty_gallery: =>
    $("#gallery .no_pics").show()
      
  display_gallery: =>
    Logger.log("Displaying the gallery for occasion " + @occasion.id)
    $("#gallery .no_pics").hide()
    @load_batch @next_batch_to_load()
    @delay = window.setInterval(@display_batch, GalleryHandler.BATCH_LOAD_DELAY)
  
  display_batch: =>
    t = new Date
    if @num_left_to_load > 0 
      Logger.log "GalleryHandler.display_batch: loaded_percentage: " + @loaded_percentage() 
      # Logger.log "achieved"  if @next_batch_load_threshold_achieved()
      @load_batch @next_batch_to_load() if @next_batch_load_threshold_achieved()
    else
      clearInterval(@delay)
  
  bind_img_size_handler: =>
    $(window).bind "resize", @adjust_thumb_width
  
  unbind_img_size_handler: =>
    $(window).unbind "resize", @adjust_thumb_width
    
  # Should be called when a window is resized (device rotated) or when enough content has been loaded such that 
  # a scroll bar now appears and causes window.innerWidth to change even though a resize event is not fired
  adjust_thumb_width: =>
    @thumb_width = (new ThumbWidthCalculator).thumb_width()
    @gallery_box.find("img").css("width", "#{@thumb_width}px")
    # Set all the heights using the aspect ratios
    for element in @gallery_box.find("img")
      do =>
        index = $(element).data("index")
        img = @image_list[index]
        $(element).css("height", @thumb_height(img))
    @gallery_box.find(".thumb_box").css("width", "#{@thumb_width}px")
    MasonryHandler.initialize(@gallery_box, ".thumb_box") 
    
  dispose: =>
    @unbind_img_size_handler()
    @num_left_to_load = 0 
    clearInterval(@delay)  
    @gallery_box.html("")  
    @photo_swipe.dispose() if @photo_swipe
    PhotoswipeHandler.dispose()
    GalleryHandler.INSTANCE = null


# ==================
# = MasonryHanlder =
# ==================
# Special cased masonry for our gallery.
class window.MasonryHandler
  
  @initialize: (container, item) =>
    # The visibility toggle below are an attempt to eliminate the effect where the photos stack up on the left before 
    # displaying. I have no idea if it will fix the problem as I cant readily reproduce.
    $(container).masonry {
      isResizable: false
      isAnimated: false
      columnWidth: GalleryHandler.INSTANCE.thumb_width
      gutterWidth: ThumbWidthCalculator.INSTANCE.margin * 2
    }
    $(container).masonry("reload")
    $(container).css("visibility", "visible")
    