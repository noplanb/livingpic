# ==========
# = Zoomer =
# ==========
class window.Zoomer  
  constructor: (el, options={}) ->    
    # Debug.log("New Zoomer on el.id: #{$(el).attr('id')}")
    @photo = options.photo
    @on_before_unsnap = options.on_before_unsnap
    @on_unsnap = options.on_unsnap
    
    if @zoom_not_supported()
      Logger.log "Zoomer: zoom_not_supported"
      @on_before_unsnap() if @on_before_unsnap?
      @on_unsnap() if @on_unsnap?
      return
      
    @on_snap = options.on_snap
    @page = options.page || "#gallery2"
    @zp = $("#zoom_photo")
    
    @max_scale_multiple_of_fullscreen = 2
    
    @el = $(el)
    @src = options.src || (@photo and  @photo.display_url()) || (@photo and @photo.thumb_display_url()) || $(el).attr("src") || $(el).css("background-image")
    @pre_snap_css_calculator = new PreSnapCssCalculator(@el, @photo)
    
    @load_zoom_photo()     
    touch_handler_options = {
      el: @page 
      scale_by: @scale_by
      pan_by: @pan_by
      unsnap: @unsnap
      zoom_and_center_on: @zoom_and_center_on
    }
    @zth = new ZoomerTouchHandler(touch_handler_options)
  
  zoom_not_supported: => Config.is_android_device() and parseFloat(Config.platform_version()) < 3.0
  
  window_center_x: => window.innerWidth / 2
  window_center_y: => window.innerHeight / 2
  
  load_zoom_photo: => 
    @zp.on("load", @after_photo_load)
    @zp.on("error", @zp_load_error)
    @zp.attr("src", @src)
  
  zp_load_error: =>
    Logger.log("Zoomer: zoom aborted becuase zoom photo failed to load.")
    @zp.off("load", @after_photo_load)
    @zp.off("error", @zp_load_error)
    @on_before_unsnap() if @on_before_unsnap?
    @zth.dispose() if @zth?
    @on_unsnap() if @on_unsnap?
    
  after_photo_load: => 
    @zp.css @pre_snap_css_calculator.pre_snap_css()
    @snap_transform_calculator = new SnapTransformCalculator(zoom_photo: @zp, pre_snap_css_calculator: @pre_snap_css_calculator)
    @snap_transform = @snap_transform_calculator.snap_transform()
    @snap()
    @max_scale = @snap_transform.scale * @max_scale_multiple_of_fullscreen
    @zp.off("load", @after_photo_load)
  
  unload_zoom_photo: =>
    @zp.css {
      display: "none"
      top: "-100px"
      left: "-100px"
    }
    @zp.attr("src", "")
      
  snap: (duration=0.3) => 
    @current_transform = clone @snap_transform
    set_transition(@zp, "#{duration or 0.3}s linear")
    @zp.on('transitionend webkitTransitionEnd', @call_on_snap)
    @zp.css transform: @transform_str(@snap_transform)
  
  call_on_snap: =>   
    @zp.off('transitionend webkitTransitionEnd', @call_on_snap)
    @on_snap() if @on_snap
  
  unsnap: => 
    return if @is_unsnapped()
    @on_before_unsnap() if @on_before_unsnap
    @zth.dispose()
    @zp.on('transitionend webkitTransitionEnd', @call_on_unsnap)
    @zp.on('transitionend webkitTransitionEnd', @window_forgets_size_bug_fix)
    @current_transform = rotate: @pre_snap_css_calculator.pre_snap_rotation(), scale: 1, translate: [0,0]
    @apply_transform(@current_transform, 0.3)
  
  call_on_unsnap: =>   
    @zp.off('transitionend webkitTransitionEnd', @call_on_unsnap)
    @unload_zoom_photo()
    @on_unsnap() if @on_unsnap
  
  # When we scale up the image window.outerWidth grows. When we scale it back to 1 the webkit webview on
  # ios at least neglects to adust window.outerWidth back down. The workaround I found for this is to
  # explicityly change the width of the image in css slightly then change it back to force a recalculation.
  window_forgets_size_bug_fix: =>
    @zp.off('transitionend webkitTransitionEnd', @window_forgets_size_bug_fix)
    original_width = @zp.width()
    @zp.width( original_width - 1 )
    @zp.width("#{original_width}px")
      
  pan_by: (x,y) => 
    @update_transform_for_pan(x,y)
    @apply_transform(@current_transform, -10)
  
  update_transform_for_pan: (x,y) =>
    translate = [@current_transform.translate[0] + x, @current_transform.translate[1] + y]
    @current_transform = @update_transform( @current_transform, "translate", translate)
    
  # Limits to prevent translating the element such that it uncovers the screen behind.
  translate_limits: => 
    x_extent = Math.floor( ( @current_el_size().w - window.innerWidth ) / 2 )
    y_extent = Math.floor( ( @current_el_size().h - window.innerHeight ) / 2 )
    {x: [@snap_transform.translate[0] - x_extent, @snap_transform.translate[0] + x_extent], y: [@snap_transform.translate[1] - y_extent, @snap_transform.translate[1] + y_extent]}
  
  limit_translate: (translate) => 
    tl = @translate_limits()
    x = Math.max(translate[0], tl.x[0])
    x = Math.min(x, tl.x[1])
    y = Math.max(translate[1], tl.y[0])
    y = Math.min(y, tl.y[1])
    [x,y]
  
  scale_by: (factor) => 
    @update_transform_for_scale_by factor
    @apply_transform(@current_transform, -10)
  
  update_transform_for_scale_by: (factor) =>
    @current_transform = @update_transform( @current_transform, "scale", @current_transform.scale * factor )
  
  update_transform_for_scale_to: (scale) =>
    @current_transform = @update_transform( @current_transform, "scale", scale )
    
  limit_scale: (factor) => 
    factor = Math.max(factor, @snap_transform.scale)
    factor = Math.min(factor, @max_scale)
    factor
  
  zoom_and_center_on: (x,y) =>
    return @snap(0.1) if @is_zoomed_in() 
    
    zoom_scale = @max_scale
    scale_factor = zoom_scale / @snap_transform.scale
    delta_x = scale_factor * (@window_center_x() - x)
    delta_y = scale_factor * (@window_center_y() - y)
    @update_transform_for_scale_to(zoom_scale)
    @update_transform_for_pan(delta_x, delta_y)
    @apply_transform(@current_transform, 0.2)
  
  is_zoomed_in: => @current_transform.scale > @snap_transform.scale
  
  is_snapped: => @current_transform.scale > 1
  
  is_unsnapped: => not @is_snapped()
    
  current_el_size: => w: @snap_transform_calculator.post_snap_rotation_dim().width * @current_transform.scale, h: @snap_transform_calculator.post_snap_rotation_dim().height * @current_transform.scale
  
  transform_str: (transform) => "translate(#{Math.floor transform.translate[0]}px, #{Math.floor transform.translate[1]}px) scale(#{transform.scale}) rotate(#{transform.rotate}deg)"
  
  update_transform: (transform, property, value) =>
    transform[property] = value
    # Make sure limits on scale and translate are not exceded
    transform.scale = @limit_scale transform.scale
    transform.translate = @limit_translate transform.translate
    transform
  
  apply_transform: (transform, duration=0.1) => 
    set_transition(@zp, "#{duration}s linear")
    @zp.css transform: @transform_str(transform)


# ========================
# = PreSnapCssCalculator =
# ========================
class window.PreSnapCssCalculator
  
  constructor: (el, photo=null) -> 
    @el = $(el)
    @photo = photo
    @sanity_check()
  
  sanity_check: =>
    if @requires_orientation_compensation() and (!@photo.width? or !@photo.height?)
      $.error "SnapTransformCalculator.sanity_check(): expecting @photo with width, and height since @photo requires_orientation_compensation." 
  
  raw_aspect: => 
    return @raw_aspect_cache if @raw_aspect_cache?
    return null unless @photo? and typeof @photo is "object" and typeof @photo.width is "number" and typeof @photo.height is "number"
    @raw_aspect_cache = if @requires_w_h_swap() then @photo.height / @photo.width else @photo.width / @photo.height
    
  pre_snap_css: => 
    return @pre_snap_css_cache if @pre_snap_css_cache?
    css = {}
    css.width = @pre_snap_css_width() + "px"
    css.top = @pre_snap_css_top() + "px"
    css.left = @pre_snap_css_left() + "px"
    css.height = if @pre_snap_css_height() then @pre_snap_css_height() + "px" else "auto"
    css.transform = "rotate(#{@pre_snap_rotation()}deg)" if @pre_snap_rotation()
    css.display = "block"
    @pre_snap_css_cache = css
          
  desired_pre_snap_state: => 
    return @desired_pre_snap_state_cache if @desired_pre_snap_state_cache?
    dpss = width: @el.width(), top: @el.offset().top, left:@el.offset().left 
    dpss.height = dpss.width/@raw_aspect() if @raw_aspect()
    @desired_pre_snap_state_cache = dpss
  
  requires_orientation_compensation: => 
    return @requires_orientation_compensation_cache if @requires_orientation_compensation_cache?
    @requires_orientation_compensation_cache = Config.is_ios_device() and @photo? and 
              @photo.orientation? and @photo.orientation isnt 1 and (!@photo.has_local_image or !@photo.has_local_image())
    @requires_orientation_compensation_cache
  
  pre_snap_rotation: => 
    return @pre_snap_rotation_cache if @pre_snap_rotation_cache?
    unless @requires_orientation_compensation()
      return @pre_snap_rotation_cache = 0
    @pre_snap_rotation_cache = switch @photo.orientation
      when 1 then 0
      when 3 then 180
      when 6 then 90
      when 8 then -90
    @pre_snap_rotation_cache
  
  pre_snap_css_width: => 
    return @pre_snap_css_width_cache if @pre_snap_css_width_cache?
    unless @requires_w_h_swap()
      return @pre_snap_css_width_cache = @desired_pre_snap_state().width 
    @pre_snap_css_width_cache = switch @photo.orientation
      when 6,8
        ra = @raw_aspect()
        $.error "SnapTransformCalculator: pre_snap_css_width(): expected raw_aspect() since orientation is non-zero" unless ra
        Math.round(@desired_pre_snap_state().width / ra)
      else
        @desired_pre_snap_state().width
    @pre_snap_css_width_cache
  
  pre_snap_css_height: =>
    return @pre_snap_css_height_cache unless @pre_snap_css_height_cache is undefined
    unless @requires_orientation_compensation()
      return @pre_snap_css_height_cache = null 
    @pre_snap_css_height_cache = switch @photo.orientation
      when 6,8
        @desired_pre_snap_state().width
      else
        @desired_pre_snap_state().width / @raw_aspect()
    @pre_snap_css_height_cache
  
  pre_snap_css_top: => 
    return @pre_snap_css_top_cache if @pre_snap_css_top_cache?
    @pre_snap_css_top_cache = @desired_pre_snap_state().top + @top_left_adustment()
  
  pre_snap_css_left: => 
    return @pre_snap_css_left_cache if @pre_snap_css_left_cache?
    @pre_snap_css_left_cache = @desired_pre_snap_state().left - @top_left_adustment()
    
  top_left_adustment: => 
    return @top_left_adustment_cache if @top_left_adustment_cache?
    unless @requires_w_h_swap()
      return @top_left_adustment_cache = 0 
    @top_left_adustment_cache = Math.round Math.abs( (@desired_pre_snap_state().width - @desired_pre_snap_state().height)/2 )
    
  requires_w_h_swap: => @pre_snap_rotation() is -90 or @pre_snap_rotation() is 90

  post_pre_snap_dim: => 
    return @post_pre_snap_dim_cache if @post_pre_snap_dim_cache?
    dim = {}
    dim.width = if @requires_w_h_swap() then @pre_snap_css_height() else @pre_snap_css_width()
    dim.height = if @requires_w_h_swap() then @pre_snap_css_width() else @pre_snap_css_height()
    dim.aspect = dim.width / dim.height
    dim.rotation = @pre_snap_rotation()
    dim.top = @pre_snap_css_top() - @top_left_adustment()
    dim.left = @pre_snap_css_left() + @top_left_adustment()
    @post_pre_snap_dim_cache = dim
  

# ===========================
# = SnapTransformCalculator =
# =========================== 
class window.SnapTransformCalculator
  
  constructor: (params={}) ->
    @zoom_photo = params.zoom_photo
    @pre_snap_css_calculator = params.pre_snap_css_calculator
    
  pre_snap_dim: =>
    return @pre_snap_dim_cache if @pre_snap_dim_cache?
    dim = {}
    dim.width = @pre_snap_css_calculator.post_pre_snap_dim().width || @zoom_photo.width()
    dim.height = @pre_snap_css_calculator.post_pre_snap_dim().height || @zoom_photo.height()
    dim.rotation = @pre_snap_css_calculator.post_pre_snap_dim().rotation
    dim.aspect = dim.width / dim.height
    dim.top = @pre_snap_css_calculator.post_pre_snap_dim().top
    dim.left = @pre_snap_css_calculator.post_pre_snap_dim().left
    @pre_snap_dim_cache = dim

  snap_rotation_needed: => 
    return @snap_rotation_needed_cache if @snap_rotation_needed_cache?
    @snap_rotation_needed_cache = @pre_snap_dim().aspect > 1
  
  post_snap_rotation_dim: =>
    return @post_snap_rotation_dim_cache if @post_snap_rotation_dim_cache? 
    dim = {}
    dim.width = if @snap_rotation_needed() then @pre_snap_dim().height else @pre_snap_dim().width
    dim.height = if @snap_rotation_needed() then @pre_snap_dim().width else @pre_snap_dim().height
    dim.aspect = dim.width / dim.height
    @post_snap_rotation_dim_cache = dim
  
  window_aspect: => window.innerWidth / window.innerHeight
  
  snap_transform: =>  
    return @snap_transform_cache if @snap_transform_cache?  
    snap_rotate = if @snap_rotation_needed() then @pre_snap_dim().rotation - 90 else @pre_snap_dim().rotation
    snap_scale = if @window_aspect() > @post_snap_rotation_dim().aspect then (window.innerWidth+2) / @post_snap_rotation_dim().width else (window.innerHeight+2) / @post_snap_rotation_dim().height
        
    # Y distance from center of el to the center of the screen.
    # Negative if center of el is below center of screen
    # Y
    @center_of_el_in_page_y = @pre_snap_dim().top + ( @pre_snap_dim().height / 2 )
    @center_of_screen_in_page_y = window.scrollY + ( window.innerHeight / 2 )
    @el_center_to_screen_center_y =  Math.floor( @center_of_el_in_page_y - @center_of_screen_in_page_y )
    
    # X
    @center_of_el_in_page_x = @pre_snap_dim().left + ( @pre_snap_dim().width / 2 )
    @center_of_screen_in_page_x = window.innerWidth / 2 
    @el_center_to_screen_center_x = Math.floor( @center_of_el_in_page_x - @center_of_screen_in_page_x )
      
    snap_translate = [-@el_center_to_screen_center_x, -@el_center_to_screen_center_y]
        
    @snap_transform_cache = translate: snap_translate, scale: snap_scale, rotate: snap_rotate
  

# ======================
# = ZoomerTouchHandler =
# ======================
class window.ZoomerTouchHandler
  
  constructor: (options) -> 
    @zp = $("#zoom_photo")
    @prevent_legacy_click()
    @add_listeners()
    
    $.error "ZoomerTouchHandler: requires a scale_by function." unless typeof options.scale_by is "function"
    @scale_by = options.scale_by
    
    $.error "ZoomerTouchHandler: requires a pan_by function." unless typeof options.pan_by is "function"
    @pan_by = options.pan_by
    
    $.error "ZoomerTouchHandler: requires a zoom_and_center_on function." unless typeof options.zoom_and_center_on is "function"
    @zoom_and_center_on = options.zoom_and_center_on
  
    $.error "ZoomerTouchHandler: requires a unsnap function." unless typeof options.unsnap is "function"
    @unsnap = options.unsnap
    
    @doc_moves = []
    @moves = []
    @pinches = []
    
  dispose: => @remove_listeners()
  
  # If we are entering the zoomer from a previous environment like the scroller where the user might have double clicked but the previous 
  # sent us here on the first click then the second click of the double click will register as a click in the zoomer. 
  # We want to prevent this unintentional click.
  prevent_legacy_click: =>
    @legacy_click_preventer = true
    setTimeout( => 
      @legacy_click_preventer = false
    ,750)
    
  remove_listeners: =>
    @zp.get(0).removeEventListener("click", @browser_click, false)
    @zp.get(0).removeEventListener("touchstart", @touchstart, false)
    @zp.get(0).removeEventListener("touchmove", @touchmove, false)
    @zp.get(0).removeEventListener("touchend", @touchend, false)
    
  add_listeners: =>
    @zp.get(0).addEventListener("click", @browser_click, false) if Config.is_running_in_browser()
    @zp.get(0).addEventListener("touchstart", @touchstart, false)
    @zp.get(0).addEventListener("touchmove", @touchmove, false)
    @zp.get(0).addEventListener("touchend", @touchend, false)

  touchstart: (e) =>
    e.preventDefault()
    @moves = []
    @pinches = []
    return @ignore_gesture() if e.touches.length > 2
    @unignore_gesture()
    @pinching_flag = false
    @moves.push e
    @handle_move()
    
  touchmove: (e) =>
    e.preventDefault()
    return @ignore_gesture() if @moves.is_blank() #ignore a gesture that did not start with a touch_start such as a residual pinch from the scroller that may have gotten us here.
    return if @ignore_gesture_flag
    @moves.push e
    @handle_move()
    
  doctouchmove: (e) =>
    doc_moves.push e
    
  touchend: (e) => 
    e.preventDefault()
    if @moves.length is 1
      @handle_click()
  
  browser_click: (e) =>
    e.preventDefault()
    e.stopPropagation()
    # alert("browser click")
    @handle_click()
    
  ignore_gesture: => @ignore_gesture_flag = true
  
  unignore_gesture: => @ignore_gesture_flag = false
    
  show: => [@starts, @moves, @ends]
  
  last_move: => @moves.last()
  
  prior_move: => @moves.last(2).first()
  
  last_pinch: => @pinches.last()
  
  prior_pinch: => @pinches.last(2).first()
  
  handle_move: => 
    if @last_move().touches.length > 1 
      @handle_pinch() 
    else if !@pinching_flag
      @handle_pan()
  
  handle_pinch: =>
    # note we must have exactly 2 fingers down to get here.
    @pinching_flag = true
    touch_identifiers = [@last_move().touches[0].identifier, @last_move().touches[1].identifier]
    @pinches.push {}
    
    if @last_move().type is "touchstart"
      for i in [0,1]
        t = @last_move().touches[i]
        @last_pinch()[t.identifier] = [t.pageX, t.pageY]
    else
      # For each changed_touch add its position by identifer in @pinches
      for i in [0, @last_move().changedTouches.length-1]
        ct = @last_move().changedTouches[i]
        @last_pinch()[ct.identifier] = [ct.pageX, ct.pageY]
      
    # For each touch_identifier if no position has been added above then add the prior postion
    @last_pinch()[ti] ||= @prior_pinch()[ti] for ti in touch_identifiers
    
    if @pinches.length > 1   
      gain = 2
      scale_factor = @size_of_pinch(@last_pinch(), touch_identifiers) / @size_of_pinch(@prior_pinch(), touch_identifiers)
      @scale_by(Math.pow(scale_factor, gain))
  
  size_of_pinch: (pinch, touch_identifiers) => 
    x1 = pinch[touch_identifiers[0]][0]
    x2 = pinch[touch_identifiers[1]][0]
    y1 = pinch[touch_identifiers[0]][1]
    y2 = pinch[touch_identifiers[1]][1]
    Math.pow( Math.pow(x1-x2, 2) + Math.pow(y1-y2, 2), 0.5 ) 
    
  handle_pan: =>
    return unless @moves.length > 1
    gain = 1.35
    x1 = touch_page_x @prior_move()
    x2 = touch_page_x @last_move()
    y1 = touch_page_y @prior_move()
    y2 = touch_page_y @last_move()
    @pan_by(gain * (x2-x1), gain * (y2-y1))
    
  handle_click: => 
    if @legacy_click_preventer
      @legacy_click_preventer = false  #Only have it take effect for one click. Sometimes the timeout doesnt fire to turn it off then you are stuck.
      return
    if @is_double_click() then @double_click() else @first_click()
  
  is_double_click: => @double_click_timer_running
  
  double_click: =>
    @clear_double_click_timer()
    @zoom_and_center_on(@moves.first().touches[0].clientX, @moves.first().touches[0].clientY)
      
  first_click: => @start_double_click_timer()
  
  start_double_click_timer: => 
    @time_mark = new Date
    @double_click_timer_running = true
    @double_click_timer = setTimeout(@click, 350)
  
  clear_double_click_timer: => 
    @double_click_timer_running = false
    clearTimeout @double_click_timer
  
  click: =>
    # alert("touchclick") 
    @clear_double_click_timer()
    @unsnap()  
    
    
    