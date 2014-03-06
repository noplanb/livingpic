# This is the gallery view for the fullwidth fast scrolling gallery.
# Deprecate and delete gallery_view.js.coffee and gallery_controller.js.coffee when this is complete.

# ======================
# = GalleryController2 =
# ======================
class window.GalleryController2
  @gallery_page_id: "gallery2" 
  
  @show: (occasion,refresh=false) => 
    # This could get called when there are no occasions, or the occasion list is incomplete
    # Try to load the occasions list if need be
    
    # We stick notify the user about an app version out of date here.
    return if VersionMgtController.notify_user_if_necessary()
        
    occasion = current_occasion() unless occasion
    occasion = Occasion.normalize_to_object(occasion)
    return Pager.change_page("occasions")  unless occasion      
        
    @init_page(occasion)
    set_current_occasion occasion
    Pager.change_page @gallery_page_id # To get the header up there early and wait on GalleryHandler.
    return if occasion.photos.is_blank()
    
    # If not refresh or occasion is already showing then no need to restart gallery handler.
    if refresh or occasion isnt @showing
      Logger.log("GalleryController2: Showing occasion #{occasion.id} with refresh = #{refresh}")
      @gallery_handler ||= new GalleryHandler2
      @gallery_handler.display_photos occasion.photos
    
    @showing = occasion

  @show_new_content: (occasion)  =>
    @show(occasion,true)

  @init_page: (occasion) => 
    GalleryHeadView2.render(occasion)
    if occasion.photos.is_blank() then NoPhotosView.show() else NoPhotosView.hide() 
    @set_zoom_holdoff()
  
  @refresh_header: => GalleryHeadView2.render(@showing)
  
  @refresh_content: (refresh_done_callback) => 
    @refresh_done_callback = refresh_done_callback
    @showing.load_from_server(refresh_done_callback)
         
  @show_current: (refresh=false) => @show(current_occasion(), refresh)
  
  @set_zoom_holdoff: => 
    # Debug.log "set zoom_holdoff"
    @zoom_holdoff = true
    setTimeout(@unset_zoom_holdoff, 1000)
    
  @unset_zoom_holdoff: =>
    # Debug.log "unset zoom_holdoff"
    @zoom_holdoff = false
  
  @android_back: => @gallery_handler && @gallery_handler.android_back()
      
  @toggle_participants: => 
    if current_occasion().photos.is_blank()
      alert "Please add a photo before adding people."
    else
      @gallery_handler and @gallery_handler.toggle_participants()
  
  @current_photo: => 
    @gallery_handler and @gallery_handler.photo_resolution_handler and Photo.find(@gallery_handler.photo_resolution_handler.high_res_ids[0])

window.current_photo = -> GalleryController2.current_photo()
   
# ===================
# = GalleryHandler2 =
# ===================
class window.GalleryHandler2

  add_event_handlers: ->
    $(document).off("photo_status_change", @on_photo_status_change)
    $(document).on("photo_status_change", @on_photo_status_change)

  constructor: ->
    GalleryHandler2.instance = @
    @scroll_el_str = "#gallery2 .scroller"
    @setup_refresher()
    @add_event_handlers();
  
  display_photos: (photos) =>
    @photos = photos
    @gallery_loader = new GalleryLoader(@photos)
    @photo_resolution_handler = new PhotoResolutionHandler(@photos)
    @start_scroller_if_necessary()
    
  zoom: (el) =>
    # Prevent a double click that was made on the occasions page from zooming a photo in the gallery
    # which can be a bit disorienting.
    return if GalleryController2.zoom_holdoff
    id = @id_from_element(el)
    photo = Photo.find(id)
    unless photo.has_device_image()
      alert "Please wait for photo to download before zooming"
      return
    @scroller.pause() if @scroller
    @photo_resolution_handler.set_high_res id
    @zoomer = new Zoomer(el, {photo: photo, on_unsnap: @unzoom})
    
  unzoom: () =>
     @scroller.resume() if @scroller
  
  start_scroller_if_necessary: =>
    return false if Config.is_running_in_browser() 
    
    # Override .content visibility in mobile.css to allow zoomer zoom elements in .content to cover the entire screen.
    $("#gallery2 .content").css overflow: "visible" unless Config.is_running_in_browser()
    if @scroller 
       @scroller.pages_added() 
       @scroller.jump_to_top()
    else 
      @start_scroller()
    true
    
  start_scroller: =>
    @scroller = new Scroller({
      scroll_el_str: @scroll_el_str, 
      page_el_str: "#gallery2 .photo_block", 
      on_stop: @on_stop,
      on_at_bottom: @scroller_at_bottom,
      on_at_top: @scroller_at_top,
      before_scroll_to: @before_scroll_to,
      refresher: @refresher,
      })
    
  before_scroll_to: () =>  
    # This was an experiment to see if i could fix the scroll stop latency when high res photos in gallery.
    # @photo_resolution_handler.set_all_low_res()
  
  on_stop: (stop_el) => 
    # Unable to find a solution to high res photos delaying scroll_stop so eliminate high res photos in gallery except for zoom.
    setTimeout(@delayed_on_stop, 100, [stop_el])
  delayed_on_stop: (stop_el) =>
    id = @id_from_element(stop_el[0])
    @photo_resolution_handler.high_res_around_id id if id
  
  id_from_element: (el) => parseInt(el.id.match(/-?\d+/).first())
    
  scroller_at_bottom: =>
    if @gallery_loader.more_for_bottom()
      @scroller.freeze()
      @gallery_loader.load_bottom()
      @scroller.pages_added()
      @scroller.unfreeze()
      true
      
  scroller_at_top: =>
    if @gallery_loader.more_for_top()
      @scroller.freeze()
      @gallery_loader.load_top()
      @scroller.pages_added()
      @scroller.unfreeze()
      true
      
  page_modified: (photo) =>
    id = Photo.normalize_to_id(photo)
    @gallery_loader.frame_modified(id)
    @scroller.scroll_el_modified() if @scroller

  edit_comment: (photo) => 
    photo = Photo.normalize_to_object photo
    if photo.is_new_record()
      AlertHandler.message("Photo must upload before you can comment on it")
    else
      @ch = ( new CommentHandler2(photo) )
      @ch.edit()
      @scroller.freeze() if @scroller?
  
  post_comment: (text) => 
    @ch.post text
    @scroller.unfreeze() if @scroller?
  
  cancel_comment: => 
    @ch.cancel() 
    @scroller.unfreeze() if @scroller?
  
  setup_refresher: => 
    options = {
      refresh_div: $("#gallery2 .refresh"),
      do_refresh: @do_refresh,
    }
    @refresher = new Refresher options
  
  do_refresh: => 
    # Dont check if the network handler is already busy.
    if NetworkHandler.is_active()
      @refresher.unchanged() 
      setTimeout(@reset_refresher, 750)
      return
    @scroller.freeze()
    GalleryController2.refresh_content(@refresh_done)
      
  refresh_done: (status) =>
    if status == Occasion.STATUS.NEW_CONTENT 
      @refresher.changed() 
      setTimeout(@reset_refresher_and_reload_page, 750)
    else if status == Occasion.STATUS.ERROR
      @refresher.error()
      setTimeout(@reset_refresher, 750)
    else
      @refresher.unchanged()
      setTimeout(@reset_refresher, 750)
  
  reset_refresher_and_reload_page: => 
    @reset_refresher()
    GalleryController2.show(GalleryController2.showing, true)
    
  reset_refresher: =>
    @scroller.scroll_to_top()
    @refresher.refresh_done()
    @scroller.unfreeze()

  toggle_participants: => 
    @revealer ||= Revealer.instance("#gallery2", {before_reveal: @before_reveal, after_hide: @after_hide})
    @revealer.toggle("right")
    
  before_reveal: => 
    ParticipantsView2.render_current()
    @scroller && @scroller.pause()
  after_hide: => 
    GalleryController2.refresh_header()
    @scroller && @scroller.resume()
  
  android_back: => 
    if @revealer && @revealer.revealed
      @revealer.hide()
    else if @zoomer and @zoomer.is_snapped()
      @zoomer.unsnap()
    else
      OccasionsController.show()

  on_photo_status_change: (event,photo) =>
    if photo instanceof Photo
      Logger.log "Photo status changed for draw_id: #{photo.draw_id} photo_id #{photo.id} new status #{photo.status}"
    else
      Logger.error "Photo status changed but no photo passed got: #{typeof photo}"
      return

    # If we are showing this photo....
    if photo.id in @photos.ids()
      if photo.status == Photo.STATUS.DUPLICATE
        GalleryController2.show(GalleryController2.showing, true)
        AlertHandler.message("Duplicate photo uploaded so removing it from album")
      else
        PhotoStatusView.update_status_text(photo)

# ================
# = NoPhotosView =
# ================
# Hide the scroller here so it doesnt cover clicks on the no_photos page
class window.NoPhotosView
  @no_photos_node: => $("#gallery2 .no_photos")
  @scroller_node: => $("#gallery2 .scroller")
  
  @show: => 
    @no_photos_node().show()
    @scroller_node().hide()
    
  @hide: => 
    @no_photos_node().hide()
    @scroller_node().show() 

# ===================
# = PhotoStatusView =
# ===================
# Move to the gallery handler b/c scope is bigger than just the photo status changing...
# $(document).ready -> PhotoStatusView.add_event_handlers()

class window.PhotoStatusView

  @update_status_text: (photo) => 
    $("#photo_status_#{photo.draw_id}").html @status_text(photo)
    $("#photo_status_#{photo.id}").html @status_text(photo)
      
  @status_text: (photo) =>
    percent_text = if photo.upload_percent then "#{photo.upload_percent}%" else "..."
    switch photo.status
      when Photo.STATUS.UPLOAD_PENDING then "Upload pending"
      when Photo.STATUS.UPLOADED then "Uploaded"
      when Photo.STATUS.UPLOADING then "Uploading #{percent_text}"
      when Photo.STATUS.UPLOAD_FAILED then "Upload Failed"
      when Photo.STATUS.DOWNLOADED then "Downloaded"
      when Photo.STATUS.DOWNLOADING then "Downloading"
      when Photo.STATUS.DOWNLOAD_ERROR then "Download Failed"
      else ""
  
# ===================
# = ParticipantsView =
# ===================
# Delete ParcicipantsView when this is complete
class window.ParticipantsView2
  @render: (occasion) => 
    $("#gallery2 .num_participants").html occasion.num_participants()
    $("#gallery2 .participants_list").html occasion.participants_full_names().join("<br/>")  
  
  @render_current: => @render current_occasion()
  
  @render_highlight_added: (added_participants) => 
    $("#gallery2 .num_participants").html "#{added_participants.length} added"
    added_participant_names = added_participants.map (n) -> "#{n.first_name} #{n.last_name}"
    all_names = current_occasion().participants_full_names()
    all_names = all_names.map (n) -> if added_participant_names.includes n then "** <strong>#{n}</strong>" else n    
    $("#gallery2 .participants_list").html all_names.join("<br/>")  
  
# ===================
# = GalleryHeadView =
# ===================
class window.GalleryHeadView2
  @render: (occasion) =>
    return unless occasion = Occasion.normalize_to_object occasion
    $("#gallery2 .occasion_name").html(occasion.name)
    $("#gallery2 .people_stats").html("#{occasion.num_participants()} people")
     
# =================
# = GalleryLoader =
# =================
# Works with the scroller to handle loading and unloading photo_blocks in the gallery so that no more than
# @max_gallery_size photos are loaded an any time so the performance of the scroller remains good.
class window.GalleryLoader  
  
  batch_size: 10
  max_gallery_size: 15
    
  constructor: (all_photos) ->
    GalleryLoader.instance = @
    @photo_block_view = new PhotoBlockView
    @gallery_frame_postioner = new GalleryFramePositioner
    @photos_node = $("#gallery2 .photos")
    
    @all_photos = all_photos  
    @all_photo_ids = @all_photos.map (p) -> p.id
        
    @top_i = 0
    @bottom_i = 0
    @has_frame_i = 0
    
    @last_i = @all_photo_ids.length - 1
    @load_initial_batch()
  
  clear_all_photos: => @photos_node.html ""
    
  loaded_ids: => @all_photo_ids[@top_i..@bottom_i]
    
  initial_batch: => @all_photo_ids[0..Math.min(@last_i, @max_gallery_size - 1)]
  
  load_initial_batch: => 
    @clear_all_photos()
    batch = @initial_batch()
    @photos_node.get(0).innerHTML = @html_for(batch, {with_frame: true})
    @gallery_frame_postioner.append_and_position batch
    @bottom_i = batch.length - 1
    @has_frame_i = @bottom_i
      
  next_batch_for_bottom: => @all_photo_ids[@bottom_i + 1 .. Math.min(@last_i, @bottom_i + @batch_size )]
  
  next_batch_for_top: => @all_photo_ids[Math.max(0, @top_i - @batch_size) .. Math.max(0, @top_i - 1)]
  
  no_more_for_top: => @top_i is 0
  more_for_top: => not @no_more_for_top()
  no_more_for_bottom: => @bottom_i is @last_i
  more_for_bottom: => not @no_more_for_bottom()
  bottom_has_frames: => @bottom_i < @has_frame_i
  num_loaded: => @bottom_i - @top_i
  
  top_batch: => @all_photo_ids[@top_i .. Math.min(@last_i, @top_i + @batch_size - 1)]
  bottom_batch: => @all_photo_ids[Math.max(0, @bottom_i - @batch_size + 1) .. @bottom_i]
  
  html_for: (batch, options={}) => 
    html = ""
    html += @photo_block_view.photo_block(photo_id, options) for photo_id in batch
    html 
         
  load_bottom: => 
    if @more_for_bottom()
      batch = @next_batch_for_bottom()
      if @bottom_has_frames()
        @load_into_frames batch
      else
        @load_with_frames batch
        @move_has_frame_i_for_load()
      @move_bottom_i_for_load()
      @unload_if_necessary("top")
      batch
    else 
      false
  
  unload_if_necessary: (top_bottom) => 
    if @num_loaded() > @max_gallery_size + (0.5 * @batch_size)
      if top_bottom is "top" then @unload_top() else @unload_bottom()
  
  load_into_frames: (batch) => 
    document.getElementById("frame_#{id}").innerHTML = @html_for([id], {with_frame: false}) for id in batch
    batch
  
  load_with_frames: (batch) => 
    @photos_node.get(0).insertAdjacentHTML( "beforeend", @html_for(batch, {with_frame: true}) )
    @gallery_frame_postioner.append_and_position batch
    
  unload_bottom: =>
    @unload_batch @bottom_batch()
    @move_bottom_i_for_unload()
        
  load_top: => 
    if @more_for_top()
      batch = @next_batch_for_top()
      @load_into_frames batch
      @move_top_i_for_load()
      @unload_if_necessary("bottom")
      batch
    else
      false
    
  unload_top: => 
    @unload_batch @top_batch()
    @move_top_i_for_unload()
    
  unload_batch: (batch) => @unload_photo_block(photo_id) for photo_id in batch
  
  move_has_frame_i_for_load: => @has_frame_i = Math.min(@last_i, @has_frame_i + @batch_size)
  move_bottom_i_for_load: => @bottom_i = Math.min(@last_i, @bottom_i + @batch_size)
  move_top_i_for_load: => @top_i = Math.max(0, @top_i - @batch_size)
  move_bottom_i_for_unload: => @bottom_i = Math.max(0, @bottom_i - @batch_size)
  move_top_i_for_unload: => @top_i = Math.min(@last_i, @top_i + @batch_size)
  
  unload_photo_block: (photo_id) => 
    el = document.getElementById("photo_block_#{photo_id}")
    el.parentNode.removeChild(el)    
  
  frame_modified: (id) => @gallery_frame_postioner.frame_modified(id)  

# =========================
# = GalleryFramePositioner =
# =========================
class window.GalleryFramePositioner
  
  constructor: ->
    GalleryFramePositioner.instance = @
    
    @ids = []
    @frame_data = {}
    @bottom = 0
    
  append_and_position: (ids) => 
    @ids = @ids.concat ids
    @position_ids ids
    ids
  
  frame_modified: (id) =>
    if frame = @frame_for(id)
      previous_height = parseInt frame.style.height
      frame.style.height = "auto"
      current_height = frame.offsetHeight
      diff_height = current_height - previous_height
      
      following_frame_ids = @ids.slice(@ids.indexOf(id)+1)
      @move_frames(following_frame_ids, diff_height)
      @frame_for(id).style.height = "#{current_height}px"
      @bottom += diff_height
      
  move_frames: (ids, distance) =>   
    for id in ids
      if f = @frame_for(id)
        f.style.top = "#{parseInt(f.style.top) + distance}px"
    
  position_ids: (ids) => @position_id(id) for id in ids
  
  position_id: (id) =>
    if frame = @frame_for(id)
      height = frame.offsetHeight
      frame.style.height = "#{height}px"
      frame.style.top = "#{@bottom}px"
      @bottom += height
      id
    else
      false
      
  frame_for: (id) => document.getElementById("frame_#{id}")
      
# ==================
# = PhotoBlockView =
# ==================  
# The html for a single photo_block
class window.PhotoBlockView
  # This should match the for y padding in galler2.css.scss for (#gallery .content)
  @GALLERY_CONTENT_X_PADDING: 16
  
  constructor: () -> @clear_cache()
  
  photo_width: => 
    @photo_width_cache ||= window.innerWidth - PhotoBlockView.GALLERY_CONTENT_X_PADDING
  
  click_event: => @click_event_cache ||= if Config.is_running_in_browser() then "onclick" else "ondrag"
    
  clear_cache: => @photo_block_cache = {}
  
  photo_height: (photo) => Math.floor @photo_width() / photo.aspect()
    
  photo_block_text: (photo) =>
    @photo_block_cache[photo.id] ||= 
    """
<div id="photo_block_#{photo.id}" class='photo_block #{photo.id}'>
  <div class='caption'>#{photo.caption or ""}</div>
  <div class='creator'><span class='by'>By</span> <span class='creator_name'>#{full_name(photo.creator)}</span></div> 
  <div class='img_box' style='height:#{@photo_height(photo)}px'>
    <img id='img_#{photo.id}' data-id='#{photo.id}' class='photo' src='#{photo.thumb_display_url()}' #{@click_event()}='GalleryHandler2.instance.zoom(this)' onerror='(new PhotoLoadErrorHandler(this, event)).handle_error()'>
  </div>
  <div class="status_date">
    <span id="photo_status_#{photo.id}" class='photo_status'>#{PhotoStatusView.status_text(photo)}</span>
    <span class='date' #{@click_event()}='PhotoInfo.show(#{photo.id})'>#{(Date.parse photo.time).toString('ddd MMM d yyyy')}</span>
  </div>
  <div class='like_button #{if photo.liked_by_user current_user() then "liked" else "not_liked"}' #{@click_event()}='(new LikeHandler2(#{photo.id})).like(event)'>
   <div class='heart'></div>
   <div class='text'>#{if photo.liked_by_user current_user() then "Liked!" else "Like?"}</div>
  </div>
  <div class='likes'>#{if photo.likes is 0 then '' else photo.likes + ' Likes' }</div>
  <div class='likers'>#{(new LikeView photo).liker_names()}</div>
  <div class='comments'>#{(new CommentsView2 photo).comments_html_str()}</div>
  <div class='new_comment comment' #{@click_event()}="GalleryHandler2.instance.edit_comment(#{photo.id})">
   <div class='box'>Write a comment</div>
  </div>
</div>
    """ 
  
  photo_block: (photo, options={}) => 
    photo = Photo.normalize_to_object(photo)
    # Tag the photo object so we can associate it with the object in the dom if its id changes.
    photo.draw_id = photo.id
    if options.with_frame then @add_frame( @photo_block_text(photo), photo ) else @photo_block_text(photo)
  
  add_frame: (text, photo) =>
    r = "<div id='frame_#{photo.id}' class='frame'>"  
    r += text
    r += "</div>"  

# =========================
# = PhotoLoadErrorHandler =
# =========================
# On Android and maybe also on IOS the photo may think it has a local image for thumb or high res when in fact that file for some
# reason does not exist. On Android this maybe because the user deleted it under livingpic in his native gallery. It also may 
# occur in IOS or Android if somehow the file failed to load completely or was corrupted in a low coverage environment but we still somehow got
# a success for the load. 
# 
# To handle this situation we detect an error of the image loading and let Photo know it has stale local image links.
class window.PhotoLoadErrorHandler
  constructor: (img, e) ->
    @event = e
    @img = $(img)
    @id = $(img).data().id
    @photo = Photo.find(@id)
    @current_src = $(img).attr("src")
    @src_type = @photo.url_type(@current_src)
    
  handle_error: =>
    Logger.log("PhotoLoadErrorHandler: img_id=#{@id} current_src=#{@current_src} src_type=#{@src_type.size}, #{@src_type.local_remote}")
    @event.stopPropagation()
    @event.preventDefault() 
    if @src_type.local_remote is "r" #remote
      if @src_type.size is "hr"
        if @photo.has_local_image()
          url = @photo.display_url()
          Logger.log("PhotoLoadErrorHandler: redirecting broken remote high_res local image at #{url}")
          @img.attr("src", url)
        else
          url = @photo.thumb_display_url()
          Logger.log("PhotoLoadErrorHandler: redirecting broken remote high_res to thumb_display_url() = #{url}")
          @img.attr("src", url)
      else # thm
        # Check to see if we have a local thumb otherwise do nothing (or we will be in an infinite loop for bad network and no local copy)
        @img.attr("src", @photo.thumb_display_url()) if @photo.has_local_thumb()
    else # local
      @photo.clear_local_url(@current_src)
      if @src_type.size is "hr" 
        url = @photo.display_url()
        Logger.log("PhotoLoadErrorHandler: redirecting broken local high_res to display_url()=#{url}")
        @img.attr("src", url) 
      else 
        url = @photo.thumb_display_url()
        Logger.log("PhotoLoadErrorHandler: redirecting broken local thumb to thumb_display_url()=#{url}")
        @img.attr("src", url)
  

# ==========================
# = PhotoResolutionHandler =
# ==========================
# All photos in the gallery must be thumbnails except for the ones around where we have scrolled because:
#  - iphone quickly runs out of memory if all pics are large.
#  - scrolling much slower if pics are large.
# PRH works closely with the scroller and when scrolling stops it sets photos around the current page to high res and sets 
# all others to low res.

class window.PhotoResolutionHandler
 
  constructor: (photos) ->  
    PhotoResolutionHandler.instance = @
    @all_photo_ids = photos.map (p) -> Photo.normalize_to_id(p)
    @high_res_ids = []
    
  high_res_around_id: (id) =>
    page = @all_photo_ids.indexOf(id)
    
    on_ids = [id]
    on_ids.push @all_photo_ids[page + 1] if page + 1 < @all_photo_ids.length
    on_ids.push @all_photo_ids[page - 1] if page - 1 >= 0 
    on_ids = @closest_to_screen_center on_ids
    @set_high_res(on_ids)
    @set_low_res_except(on_ids)
  
  closest_to_screen_center: (ids) =>
    center_of_screen = window.scrollY + ( window.innerHeight / 2 )
    closest = null
    for id in ids
      img = $("#img_#{id}")  
      if img.length is 0   
        # When scrolling up fast sometimes the frame above the id has not been loaded yet. If it is not there skip it when calculating closest_to_center.
        Debug.log "PhotoResolutionHandler.closest to center no image #{id} skipping."  
        continue
      center_of_img = img.offset().top + (img.height()/2)
      distance = Math.abs(center_of_screen-center_of_img)
      closest = [id, distance] if !closest or distance < closest[1]  
    return [closest[0]]
      
    
  set_high_res: (on_ids) => 
    on_ids = to_array on_ids
    for id in on_ids
      continue if @high_res_ids.includes id
      @high_res_ids.push id
      # Using a jquery find below is expensive. And delay in this method kills the scroller. Therfore I added ids 
      # in the DOM for the img's and use a javascript native method to find and update the src.
      img = document.getElementById("img_#{id}")
      img.src = Photo.find(id).display_url() if img
    @high_res_ids
  
  set_low_res_except: (on_ids) =>
    for id in clone(@high_res_ids)
      continue if on_ids.includes id
      @high_res_ids.splice(@high_res_ids.indexOf(id), 1)
      img = document.getElementById("img_#{id}")
      img.src = Photo.find(id).thumb_display_url() if img
    @high_res_ids
  
  set_all_low_res: => @set_low_res_except []
    
  actual_high_res_ids: => @all_photo_ids.filter((id) => document.getElementById("img_#{id}") and not document.getElementById("img_#{id}").src.match(/thumb/) )
  actual_high_res_index: => @actual_high_res_ids().map (id) => @all_photo_ids.indexOf(id)
    
# ================
# = CommentsView =
# ================
# Delete CommentsView in old pic_detail.js code when we are happy with this.
class window.CommentsView2

 constructor: (photo) ->
   @photo = photo

 @comment_html_str: (comment) =>
   "<div class='comment'>
        <div class='user'>#{full_name(comment.user)}</div>
        <div class='body'>#{comment.body}</div>
    </div>"

 comments_html_str: (n=-1) => 
   r = ""
   r += CommentsView2.comment_html_str(c) for c in @photo.comments.first(n)
   r
   

# ===================
# = EditCommentView =
# ===================
#  Note the edit_textarea widget takes care animating itself and calls our handlers when events occur. This edit comments view
#  just takes care of action we need to take with regard to other elements on the page when the edit_textarea form is shown or hiden.
class window.EditCommentView
  constructor: (photo) -> 
    @photo = photo
      
  show: => 
    $("#gallery2 .content").css opacity:0
    EditTextarea.instance("edit_comment").edit()
    
  hide: => $("#gallery2 .content").css opacity:1


# ====================
# = CommentAnimation =
# ====================  
class window.CommentAnimation
  
  constructor: (photo) ->
    @photo = Photo.normalize_to_object(photo)
    @last_comment = $("#gallery2 .photo_block.#{@photo.id} .comments .comment").last()
    @animate()

  animate: => 
    @last_comment.css("-webkit-backface-visibility", "hidden")
    set_transition(@last_comment, "-10s linear") 
    @last_comment.css transform: "translate3d(#{window.innerWidth}px, 0px, 0px)"
    setTimeout(@animate2, 750)
  
  animate2: =>
    @last_comment.off('transitionend webkitTransitionEnd')
    @last_comment.on('transitionend webkitTransitionEnd', @animate3)    
    # Note I did not put the following backface hiddin in the css for all comments becuase for some reason it slows down
    # showing and hiding the new comments view. Have no idea why. This is to prevent flicker at the end of the animation.
    set_transition(@last_comment, "0.2s linear") 
    @last_comment.css transform: "translate3d(0px, 0px, 0px)"
  
  animate3: =>
    @last_comment.off('transitionend webkitTransitionEnd')
    @last_comment.css("-webkit-backface-visibility", "visible")
    set_transition(@last_comment, "none") 
    
# ===================
# = CommentHandler2 =
# =================== 
# Eliminate olde CommentHandler in pic_detail.js when we are ok with this one.
class window.CommentHandler2
    
  constructor: (photo) ->
    CommentHandler2.instance = @
    @photo = Photo.normalize_to_object(photo)
    @text_entry_field = $("#gallery2 .new_comment_block textarea")
    @comments = $("#gallery2 .photo_block.#{@photo.draw_id} .comments")
    @ecv = new EditCommentView @photo
  
  edit: => 
    @ecv.show()
  
  cancel: => 
    @ecv.hide()
      
  post: (text) => 
    @ecv.hide()
   
    # Note edit_textarea widget which is used for this handles the case of blank text being posted. So 
    # you are always assured of text being present. See widget.js  
    comment = @comment_obj text  
    @insert_into_dom(comment)
    new CommentAnimation @photo
    GalleryHandler2.instance.page_modified(@photo)
    @save_locally(comment)
    setTimeout((=> @save_to_server(comment)), 3000)
  
  comment_obj: (text) => {body: text, user: current_user()}
  
  save_locally: (comment) => @photo.add_comment comment
  
  insert_into_dom: (comment) => @comments.append( CommentsView2.comment_html_str comment )
    
  save_to_server: (comment) =>
    NetworkHandler.instance({
      url: Config.base_url() + "/photos/comment/#{@photo.id}",
      data: comment,
      type: "POST",
      dataType: "json",
      success: (response) =>
        @photo.comments = response
        @photo.save()
      error: -> Pager.change_page "network_error"
    }).run()      
    
# ================
# = Like Handler =
# ================
# Delete LikeHandler in old pic_detail.js code when we are happy with this.
# Note I eliminated the feature of max_names_length with and option to click to see all 
# names on this as we rarely will have too many likes on a photo and we have enough space to show all.
# This simplification eleminates a click handler on the gallery page which may improve performance.
class window.LikeHandler2

 constructor: (photo) ->
   @photo = Photo.normalize_to_object photo

 # If the user likes the button, register it
 like: (e) =>
   e.stopPropagation()
   e.preventDefault()
   return if @photo.liked_by_user current_user()
   @update_local_photo_if_necessary()
   (new LikeAnimation @photo).animate()
   # Delayed so it doesnt interfere with any animations we do.
   setTimeout(@send_like_to_server, 3000)
 
 send_like_to_server: =>
   # In case the connectivity is bad, we go ahead and update the liked count
   NetworkHandler.instance({
     url: Config.base_url() + "/photos/like/#{@photo.id}",
     type: "POST",
     dataType: "json",
     retry_count: 0,
     success: (response) =>
       @photo.likers = response
       @photo.likes = @photo.likers.length
       @photo.save();
     error: -> Logger.log "Error sending like."
   }).run()

 update_local_photo_if_necessary: => 
   unless @photo.liked_by_user current_user()
     if @photo.likes then @photo.likes++ else @photo.likes = 1
     if @photo.likers then @photo.likers.unshift(current_user()) else @photo.likers = [current_user()]


# ============
# = LikeView =
# ============
class window.LikeView
  
  constructor: (photo) ->
    @photo = photo
    @photo_block = $(".photo_block.#{@photo.id}")
    
  render: =>
    @render_like_button()
    @render_likes()
    @render_likers()
    GalleryHandler2.instance.page_modified(@photo)
    
  render_likes: =>
    @photo_block.find(".likes").get(0).innerHTML = "#{@photo.likes} Likes"
    
  render_likers: =>
    @photo_block.find(".likers").get(0).innerHTML =  @liker_names()
  
  liker_names: =>
    other_liker_names = []
    if @photo.likers instanceof Array 
      # first check if it includes the current_user:
      other_likers = (liker for liker in @photo.likers when liker.id != current_user_id())
      other_liker_names = other_likers.map( (user) -> first_and_last_initial(user))
      other_liker_names.unshift("You") if @photo.liked_by_user current_user() 
    return other_liker_names.to_sentence()
  
  render_like_button: =>
    like_button = @photo_block.find ".like_button"
    if @photo.liked_by_user current_user()
      like_button.find(".text").get(0).innerHTML = "Liked!"
      like_button.removeClass "not_liked"
      like_button.addClass "liked"
    else
      like_button.find(".text").get(0).innerHTML = "Like?"
      like_button.removeClass "liked"
      like_button.addClass "not_liked"

# =================
# = LikeAnimation =
# =================
class window.LikeAnimation
  
  constructor: (photo) ->
    window.npb_elapsed = new Date - window.npb_start
    @heart = $("#gallery2 .animated_heart")
    @photo = Photo.normalize_to_object(photo)
    @photo_id = Photo.normalize_to_id(photo)
    img = $("#gallery2 .photo_block.#{@photo_id} img")
    @y_center_of_img = Math.floor(img.offset().top - $("#gallery2 .content").offset().top + img.height()/2)
    @x_center_of_img = Math.floor($("#gallery2").width()/2)
        
  move_to_button: (scale) =>
    btn = $("#gallery2 .photo_block.#{@photo_id} .heart")
    y_center_of_button = btn.offset().top - $("#gallery2 .content").offset().top + btn.height()/2 
    x_center_of_button = btn.offset().left + btn.width()/2
    y_move_to_button = Math.floor( (y_center_of_button - @y_center_of_img) / scale )
    x_move_to_button = Math.floor( (x_center_of_button - @x_center_of_img) / scale )
    {x: x_move_to_button, y: y_move_to_button}
          
  animate: =>
    set_transition(@heart, "none")
    @heart.css({transform: "none", top: "#{@y_center_of_img}px", opacity: "1.0", "z-index": 6})
    @heart.css transform: "translate3d(0px 0px 200px)"
    setTimeout(@animate2, 10)
  
  animate2: =>
    @heart.off('transitionend webkitTransitionEnd')
    @heart.on('transitionend webkitTransitionEnd', @animate3)
    set_transition(@heart, "0.3s linear")
    @heart.css({transform: "scale(10) translate3d(0px, 0px, 200px) rotateY(360deg)", opacity: "0.8"})
  
  animate3: (e) =>
    # Note we get multiple events for each css that completes a transition. We only want to execute once.
    return unless e.originalEvent.propertyName.match /transform/
    @heart.off('transitionend webkitTransitionEnd')
    @heart.on('transitionend webkitTransitionEnd', @animate4)
    scale = 2.2
    set_transition(@heart, "0.2s linear")
    # We move the heart up 1px in z direction so rotate doesnt hide half the heart behind the img. Elements lose their z-index when transformed 3d.
    @heart.css({transform: "scale(#{scale}) translate3d(#{@move_to_button(scale).x}px, #{@move_to_button(scale).y}px, 200px)", opacity: "1.0"})
    
  animate4: (e) =>
    return unless e.originalEvent.propertyName.match /transform/ # Because we get an event for the opacity transition as well.
    @heart.off('transitionend webkitTransitionEnd')
    (new LikeView @photo).render()
    @heart.off('transitionend webkitTransitionEnd')
    @heart.css("transition", "-10s linear")
    @heart.css({opacity: "0"; transform: "none", top: "0px";})

window.current_photo = =>
  GalleryController2.current_photo()

class window.PhotoInfo
  @show: (photo_id) =>
    photo = Photo.find(photo_id)
    alert(photo.pps())
