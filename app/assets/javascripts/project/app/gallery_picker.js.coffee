# ===========================
# = GalleryPickerController =
# ===========================
class window.GalleryPickerController
  @show: => 
    Pager.change_page "gallery_picker"
    @fixed_grid_layout_calculator = new FixedGridLayoutCalculator
    @add_event_handlers()
    PickerPhotoGetter.init @loaded 
    
  @add_event_handlers: =>
    event_type = if Config.is_running_in_browser() then "mouseover" else "touchstart"
    $("#gallery_picker .content").get(0).removeEventListener(event_type, @handle_content_event, true)
    $("#gallery_picker .content").get(0).addEventListener(event_type, @handle_content_event, true)
    
  # Must call before_hide before leaving the page.
  # I was going to add it in a pagebeforehide event handler but I was not sure if there would be a race condition of that event being 
  # picked up off the queue and the page being hidden so safer to call explicitly here.
  # Addresses the browser bug relating improperly positioning absolutes on a div that is display none and has been scrolled. See gallery_picker.txt for details. 
  @before_hide: => 
    PickerPhotoGetter.terminate()
    GalleryPickerView.remove_all_photo_blocks()
    
  @loaded: =>
    @all_photos = PickerPhotoGetter.all_photos
    @ph = new PickHandler
    @render @all_photos
  
  @render: (photos) =>
    @content_div_grower = new ContentDivGrower(photos, @fixed_grid_layout_calculator)
    @sl = new SimpleLoader photos
    @sl.initial_load()
  
  @toggle_pick: (el, e) => 
    e.preventDefault() if e
    e.stopPropagation() if e
    @ph.toggle_pick(el)
  
  @all: => @render PickerPhotoGetter.all_photos
  
  @selected: (e) => 
    if @selected_photos().is_blank()
      e.stopPropagation()
      e.preventDefault()
      alert "None selected. Click the check mark on a photo first." 
      return
    else 
      @render @selected_photos()
  
  @selected_photos: => PickerPhotoGetter.all_photos.filter (p) => @ph.selected_list.includes p.id
  
  @is_selected: (photo) => 
    id = Photo.normalize_to_id photo
    @ph and @ph.id_is_selected(id)
  
  @cancel: => 
    @before_hide()
    UserHandler.go_home()

  # Done with the picks
  @done: =>
    for photo in @selected_photos()
      current_occasion().new_photo(
        tmp_file_uri: PhotoNormalizer.display_url(photo), 
        width: PhotoNormalizer.width(photo),
        height: PhotoNormalizer.height(photo),
        aspect_ratio: PhotoNormalizer.aspect_ratio(photo),
        latitude: PhotoNormalizer.latitude(photo), 
        longitude: PhotoNormalizer.longitude(photo), 
        orientation: PhotoNormalizer.orientation(photo),
        caption: photo.caption, 
        creator: current_user(), 
        comments:[], 
        likes:0
        )
    @before_hide()
    GalleryController2.show_current(true)

  @find_photo_by_id: (id) => 
    for p in PickerPhotoGetter.all_photos
      return p if parseInt(p.id) is parseInt(id)
    return null
    
  @zoom: (el) => 
    photo = @photo_from_el el
    @pzv = new PickerZoomView(el, photo)
  
  # Deprecated because of android bug. Search for "on_scroll_stop" in android_2.2_quirks for details
  # @on_scroll_stop: => 
  #   position = $("#gallery_picker").scrollTop()
  #   index = @sl.index_for_position position
  #   PickerPhotoGetter.load_for_index index
  #   @sl.load_for_position position
  
  # @handle_touch: (el) => 
  #   index = $(el).data().index
  #   PickerPhotoGetter.load_for_index index
  #   @sl.load_for_index index
    
  @handle_content_event: (e) =>
    @content_event = e
    position = if Config.is_running_in_browser() then e.pageY else e.targetTouches[0].pageY
    index = @index_for_position position
    PickerPhotoGetter.load_for_index(index, @after_load)
  
  @after_load: (index) =>
    @sl.load_for_index index
    @content_div_grower.grow()
    
  @photo_from_el: (el) => @find_photo_by_id $(el).data().photo_id
  
  @index_for_position: (position) => @fixed_grid_layout_calculator.index_for_y_position(position)
  
  @edit_caption: (el, e) => 
    e.preventDefault() if e
    e.stopPropagation() if e
    photo =  @photo_from_el el
    @pzv.unsnap() if @pzv
    @pch = new PickerCaptionHandler photo
    @pch.edit()
  
  @post_caption: (text, photo) => @pch.post(text)
  
  @cancel_caption: => @pch.cancel()

# =====================
# = PickerPhotoGetter =
# =====================
# Gets photos from the native albums on the phone. 
class window.PickerPhotoGetter
  
  @init: (callback) => 
    @batch_size = 8
    @all_photos = []
    @more_to_load = true
    @load_for_index(0, callback)
  
  @terminate: => 
    @more_to_load = false
    @all_photos = []
  
  @load_for_index: (index, callback) => 
    @callback = cb: callback, index: index
    if @near_end(index) and @more_to_load
      @get_next_batch(callback) 
    else
      @callback_if_necessary()
  
  @near_end: (index) => @all_photos.length - index < 3 * @batch_size 
      
  @get_next_batch: (callback) =>
    Debug.log "PhotoGetter: next batch with more_to_load = #{@more_to_load}"
    if not @more_to_load
      @callback_if_necessary()
      return
    offset = @all_photos.length
    if Config.is_running_in_browser() then @simulate_get_batch(@batch_size, offset) else @get_batch(@batch_size, offset)
  
  @get_batch: (count, offset) => plugins.AlbumInterface.getPhotosWithThumbs(@add_batch, Debug.fail, count, offset, [Config.app_photo_album], false)
  
  @simulate_get_batch: (count, offset) => @add_batch Photo.all()[offset..offset+count-1]
  
  @add_batch: (batch) => 
    @more_to_load = false if batch.length < @batch_size
    @all_photos.push p for p in batch
    @callback_if_necessary()
    Debug.log "PhotoGetter: add batch with more_to_load = #{@more_to_load}"
  
  @callback_if_necessary: => 
    @callback.cb(@callback.index) if @callback? and typeof @callback.cb is "function"
    @callback = null
      

# ===================
# = PhotoNormalizer =
# ===================
# Normalizes between simulated browser and device. Ideally normalization between ios and android should happen in AlbumInterface.js
# Note some of this normalizition should probably be moved to the respective AlbumInterface.js or album_controller.js.
class window.PhotoNormalizer
  @thumb_display_url: (obj) => if typeof obj.thumb_display_url is "function" then obj.thumb_display_url() else obj.thumb_display_url
  
  @display_url: (obj) => if typeof obj.display_url is "function" then obj.display_url() else obj.display_url
  
  @update_caption: (photo, text) =>
    if photo instanceof Photo
      photo.update_caption text
    else
      photo.caption = text
      
  @width: (photo) => photo.width
  @height: (photo) => photo.height
  
  @aspect_ratio: (photo) => 
    return photo.aspect_ratio if photo.aspect_ratio  #for simulation in browser.
    p_a = parseFloat(photo.width) / parseFloat(photo.height)
    p_a = 1/p_a if @orientation(photo) is 6 or @orientation(photo) is 8
    return p_a unless isNaN p_a
    t_a = parseFloat(photo.thumb_width) / parseFloat(photo.thumb_height)
    return t_a unless isNaN t_a
    return 0.75
    
  @latitude: (photo) => 
    p_lat = parseFloat photo.latitude
    return p_lat unless isNaN p_lat
    return current_location().latitude
    
  @longitude: (photo) => 
    p_long = parseFloat photo.longitude
    return p_long unless isNaN p_long  
    return current_location().longitude
    
  @orientation: (photo) =>
    return photo.orientation || 1

# ========================
# = PickerCaptionHandler =
# ========================
class window.PickerCaptionHandler
  
  constructor: (photo) ->
    @photo = photo 
    @pcv = new PickerCaptionView photo
  
  edit: => @pcv.show()
  
  post: (text) =>
    PhotoNormalizer.update_caption(@photo, text)
    @pcv.post()
    
  cancel: => @pcv.hide()
    
# =========================
# = PickerCaptionView =
# =========================
class window.PickerCaptionView
  
  constructor: (photo) -> 
    @photo = photo
    @photo_block = $("#gp_photo_block_#{@photo.id}")
  
  caption_el: => @photo_block.find(".caption")
  
  show: =>
    text = @photo.caption
    EditTextarea.instance("gp_edit_caption").edit(text, @photo)
    $("#gallery_picker .content").css opacity:0
  
  hide: => 
    $("#gallery_picker .content").css opacity:1
  
  post: => 
    @add_caption_to_dom(@photo.caption)
    @hide()
    @animate_caption()
  
  add_caption_to_dom: (text) =>
    @caption_el().remove()
    $caption = $(GalleryPickerView.caption_html(@photo.id, text)).css opacity:0
    @photo_block.append $caption
  
  animate_caption: => 
    el = @caption_el()
    start_y = Math.min( 0, -(el.position().top - 50) )
    set_transition(el, "-10s linear")
    el.css transform: "translateY(#{start_y}px)"
    setTimeout(@animate_caption2, 100)
  
  animate_caption2: =>
    el = @caption_el()
    el.css opacity:0.8
    set_transition(el, "300ms linear")
    el.css transform: "translateY(0px)"
    
    
# ==================
# = PickerZoomView =
# ==================
class window.PickerZoomView
  
  @pick_button: => $("#gallery_picker .icon.global.pick")
  @global_buttons: => $("#gallery_picker .icon.global")
  
  @unzoom: => PickerZoomView.global_buttons().hide()
  
  constructor: (el, photo) ->
    @photo_block = $(el)
    @photo = photo
    @zoom()
      
  zoom: =>
    @zoomer = new Zoomer(@photo_block, {
      src: PhotoNormalizer.display_url(@photo)
      on_before_unsnap: PickerZoomView.unzoom
      on_snap: @setup_buttons
      page: "#gallery_picker"
      photo: @photo
    })
  
  setup_buttons: => 
    if GalleryPickerController.is_selected @photo 
      PickerZoomView.pick_button().addClass "selected" 
    else 
      PickerZoomView.pick_button().removeClass "selected"
    
    PickerZoomView.global_buttons().data photo_id:@photo.id 
    PickerZoomView.global_buttons().show()
  
  unsnap: => @zoomer.unsnap() if @zoomer.is_snapped()
    
    
# ===============
# = PickHandler =
# ===============
class window.PickHandler
  constructor: -> 
    @global_pick_button = $("#gallery_picker .icon.global.pick")
    @selected_list = []
  
  toggle_pick: (el) => 
    id = $(el).data().photo_id
    local_pick_button = document.getElementById "gp_pick_#{id}"
    $(local_pick_button).toggleClass "selected"
    @global_pick_button.toggleClass "selected"
    if $(el).hasClass "selected" then @add_to_selected(id) else @remove_from_selected(id)
    
  add_to_selected: (id) => 
    return if @selected_list.indexOf(id) >= 0 
    @selected_list.push id
  
  remove_from_selected: (id) =>
    pos = @selected_list.indexOf id
    @selected_list.splice(pos, 1) if pos >= 0 
    
  id_is_selected: (id) => @selected_list.indexOf(id) >= 0
    
# =====================
# = GalleryPickerView =
# =====================
class window.GalleryPickerView
  @caption_html: (photo_id, caption) => "<div class='caption' onclick='GalleryPickerController.edit_caption(this, event)' data-photo_id=#{photo_id}>#{caption}</div>"
  
  @remove_all_photo_blocks: () => 
    $("#gallery_picker .photos").html ""
    $("#gallery_picker .photos").get(0).scrollTop = 0

  constructor: (photos) -> 
    @photos = photos
    
  add_photo_blocks: (indexes) => 
    $("#gallery_picker .photos").get(0).insertAdjacentHTML( "beforeend", @photo_blocks indexes )
    
  remove_photo_blocks: (indexes) => 
    $("#gp_photo_block_#{id}").remove() for id in indexes.map (i) => @photos[i].id
  
  photo_block: (index) => 
    photo = @photos[index]
    selected = if GalleryPickerController.is_selected photo  then "selected" else ""
    lc = new FixedGridLayoutCalculator
    height = lc.height
    width = lc.width
    top = lc.top(index)
    left = lc.left(index)
    caption = if photo.caption then GalleryPickerView.caption_html(photo.id, photo.caption) else ""
    thumb_url = PhotoNormalizer.thumb_display_url photo
    
    """
    <div id="gp_photo_block_#{photo.id}" class="photo_block" data-photo_id=#{photo.id} data-index=#{index}
         onclick="GalleryPickerController.zoom(this)"
         style="height:#{height}px; width:#{width}px; top:#{top}px; left:#{left}px; background-image:url('#{thumb_url}')">
      <div class="icon icon_edit" data-photo_id=#{photo.id} onclick="GalleryPickerController.edit_caption(this, event)"></div>
      <div id="gp_pick_#{photo.id}" class="icon pick #{selected}" data-photo_id=#{photo.id} onclick="GalleryPickerController.toggle_pick(this, event)"></div>
      #{caption}
    </div>
    """
  photo_blocks: (indexes) => indexes.map((i) => @photo_block i).join("")

# =================================
# = FixedGridLayoutCalculator =
# =================================    
class window.FixedGridLayoutCalculator
  
  constructor: (num_cols, gutter) -> 
    @num_cols = num_cols || 2
    @gutter = gutter || 4
    @tot_gutter = @gutter*(@num_cols + 1)
    @width = Math.floor( (window.innerWidth - @tot_gutter) / @num_cols )
    @height = @width
  
  top: (index) => 
    row = Math.floor(index/@num_cols)
    top = row * (@height + @gutter)
      
  left:(index) => 
    col = index % @num_cols
    left = @gutter + (col * ( @width + @gutter))
  
  index_for_y_position: (pos) =>
    row = Math.floor( pos / (@height + @gutter) )
    index = row * @num_cols
  
  bottom: (index) => @top(index) + @height
  
# ================
# = SimpleLoader =
# ================
class window.SimpleLoader
  
  constructor: (photos) -> 
    @batch_size = 30
    @buffer_size = 60
    
    @all_photos = photos
    
    @loaded_top = null
    @loaded_bottom = null
    
    @gpv = new GalleryPickerView(@all_photos)
    
  last: => @all_photos.length - 1
  
  initial_load: => 
    GalleryPickerView.remove_all_photo_blocks()
    @load_range(0,@buffer_size)
  
  loaded: => if @loaded_top? then [@loaded_top..@loaded_bottom] else [] 
  
  load: (indexes) => @gpv.add_photo_blocks(indexes)
  
  unload: (indexes) =>  @gpv.remove_photo_blocks(indexes)
      
  load_top_bot_for_index: (i) => 
    if @is_near_top(i) 
      @load_top() 
    else if @is_near_bottom(i) 
      @load_bottom()
  
  load_for_index: (i) => 
    half_buffer = Math.abs(@buffer_size/2)
    top = i - half_buffer
    bottom = i + half_buffer
    @load_range(top, bottom)
  
  is_near_top: (i) => i < @loaded_top + 10
  
  is_near_bottom: (i) => i > @loaded_bottom - 10
     
  load_top: =>
    top = @loaded_top - @batch_size 
    bottom = top + @buffer_size
    @load_range(top, bottom)
  
  load_bottom: => 
    bottom = @loaded_bottom + @batch_size
    top = bottom - @buffer_size
    @load_range(top, bottom)
    
  load_range: (top, bottom) =>  
    top = Math.max(0, top)  
    bottom = Math.min(@last(), bottom)
    goal_to_load = [top..bottom]
    
    to_load = goal_to_load.minus(@loaded())
    to_unload = @loaded().minus(goal_to_load)
    
    @load to_load
    @unload to_unload
    
    @loaded_top = top
    @loaded_bottom = bottom
      
  id_for_el: (el) => $(el).data().photo_id 
  
  index_for_id: (id) =>
    for p,i in @all_photos
      return i if p.id is id
    return false
       
  actual_loaded: => $("#gallery_picker .photo_block").get().map (el) => @index_for_id(@id_for_el(el))
      
# ====================
# = ContentDivGrower =
# ====================
# This was added to handle an android bug. Search for "on_scroll_stop" in android_2.2_quirks.txt for details.
class window.ContentDivGrower
  
  constructor: (photos, fixed_grid_layout_calculator) ->
    @photos = photos
    @fglc = fixed_grid_layout_calculator
    @grow()
    
  grow: => 
    height = Math.max(@fglc.bottom(@photos.length) + 50, window.innerHeight)
    $("#gallery_picker .content").css height: "#{height}px"
  

# ==================
# = ScrollDetector =
# ==================
# This was deprecated to fix an android bug. Search for "on_scroll_stop" in android_2.2_quirks.txt for details.
# class window.ScrollStopDetector
#   
#   constructor: (el, callback) -> 
#     ScrollStopDetector.instances ||= {}
#     ScrollStopDetector.instances[el] = @
#     
#     @el = $(el)
#     @call_back = callback
#     @add_event_handlers()
#   
#   add_event_handlers: => 
#     $(@el).off "scroll", @onscroll
#     $(@el).on "scroll", @onscroll
#     
#   onscroll: => 
#     clearTimeout @timer if @timer
#     @timer = setTimeout(@call_back, 200)    
    