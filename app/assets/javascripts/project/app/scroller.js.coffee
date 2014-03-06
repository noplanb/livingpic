# This version of Scroller is built from scratch and does not rely on iScroll. 

# --------------------
# ScrollerTouchHandler
# --------------------
# See iphone_scroll.txt for documentation
# Only one instance sof ScrollerTouchHandler should ever be created for an element. Error invoker tries to instantiate more
# than one.
class window.ScrollerTouchHandler
  
  @instances = {}
  
  constructor: (options={}) ->
    @scroll_el_str = options.scroll_el_str
    
    @scroll_el = $(@scroll_el_str)
    $.error "ScrollerTouchHandler: requires a scroll_el_str to find a unique element that is being scrolled." unless @scroll_el.length is 1
    
    $.error "ScrollerTouchHandler: Cant create more than one instance for scroll_el_str: #{@scroll_el_str}" if ScrollerTouchHandler.instances[@scroll_el_str]
    ScrollerTouchHandler.instances[@scroll_el_str] = @    
        
    $.error "ScrollerTouchHandler: requires move_end function." unless typeof options.move_end is "function"
    @move_end = options.move_end
    
    $.error "ScrollerTouchHandler: requires a move_px function." unless typeof options.move_px is "function"
    @move_px = options.move_px
    
    $.error "ScrollerTouchHandler: requires a transition_running function." unless typeof options.transition_running is "function"
    @transition_running = options.transition_running
    
    $.error "ScrollerTouchHandler: requires a stop_scrolling function." unless typeof options.stop_scrolling is "function"
    @stop_scrolling = options.stop_scrolling
        
    @add_listeners()
    
    @moves = []
    @speeds = []
    
  add_listeners: =>    
    @scroll_el.parent().get(0).addEventListener("touchstart", @touchstart, false)
    @scroll_el.parent().get(0).addEventListener("touchmove", @touchmove, false)
    @scroll_el.parent().get(0).addEventListener("touchend", @touchend, false)
  
  remove_listeners: =>    
    @scroll_el.parent().get(0).removeEventListener("touchstart", @touchstart, false)
    @scroll_el.parent().get(0).removeEventListener("touchmove", @touchmove, false)
    @scroll_el.parent().get(0).removeEventListener("touchend", @touchend, false)
    
  pause: => @remove_listeners()
  resume: => @add_listeners()
  freeze: => @frozen = true
  unfreeze: => @frozen = false
              
  touchstart: (e) => 
    e.preventDefault()
    e.stopPropagation()
    return if @frozen
    # I set the start event as a move here so we can immediately start calcuating speed on the first move event.
    # This is important for generating a scroll_stop in the case where transition_running and user puts his finger 
    # down to stop but moves it a bit to generate just a single move. In this case cancel_scroll_stop will trigger
    # but we still want to be able to send a scroll_stop based on the speed calcuated from the touch_start event to the
    # first move event.
    @set_stop_scrolling_timer() if @transition_running()
    @moves  = [e]
    @speeds = []
    @last_move = e  
    if not @transition_running() then @possible_click = true else @possible_click = false
    
  touchmove: (e) =>
    e.preventDefault()
    e.stopPropagation()
    return if @frozen
    @cancel_stop_scrolling_timer()
    @current_move = e
    return @pinch(e) if e.touches.length is 2
    @move_px(@current_delta_px()) if not @transition_running()
    @stop_scrolling() if @transition_running() and @current_speed() and Math.abs(@current_speed) < 0.7 
    @speeds.push @current_speed() if @current_speed()
    @moves.push e
    @last_move = @current_move
    
  touchend: (e) => 
    e.preventDefault()
    e.stopPropagation()
    return if @frozen
    @touch_end = e
    return if @frozen
    return @dispatch_click(e) if @is_click()
    @move_end @end_speed() 
    # @display_gesture_profile()
  
  is_click: => @possible_click && @moves.length <= 1
  
  # Search for "ondrag" in android_2.2_quirks.text for an explanation of why I use the drag mouse event here.
  dispatch_click: (e) => 
    $(e.target).trigger("drag")
  
  pinch: (e) => @dispatch_click(e)
    
  # In case the user sets his finger down on a scrolling page and generates no move events.
  set_stop_scrolling_timer: => 
    @stop_scrolling_timer = setTimeout(@stop_scrolling, 30)
    
  cancel_stop_scrolling_timer: => 
    clearTimeout @stop_scrolling_timer
         
  current_delta_px: => touch_page_y(@last_move) - touch_page_y(@current_move)
  
  current_delta_ms: => @current_move.timeStamp - @last_move.timeStamp
  
  current_speed: => 
    s = 1.0 * @current_delta_px() / @current_delta_ms()
    # We get spurious incorrect high instantaneous speeds when touch moves are delayed by some activity cap these.
    s = Math.min(6,s)
    s = Math.max(-6,s)
    s
  
  average_last_n_speeds: (n) => @speeds.last(n).mean()
  
  move_ended_with_stop: => 
    return true if @speeds.length is 0
    Math.abs(to_array(@speeds.last(2)).mean()) < 0.08
  
  end_speed: => 
    return 0 if @speeds.length is 0
    to_array(@speeds.last(4)).mean()
       
  display_gesture_profile: =>
    last_move = null
    min_speed = 100
    max_speed = 0
    min_time = 1000
    max_time = 0
    times = []
    for move in @moves
      if last_move
        current_y = touch_page_y move
        last_y = touch_page_y last_move
        current_t = move.timeStamp
        last_t = last_move.timeStamp
        distance = current_y - last_y
        time = current_t - last_t
        min_time = time if time < min_time
        max_time = time if time > max_time
        times.push time
        speed = 1.0*distance/time
        abs_speed = Math.abs speed
        min_speed = abs_speed if abs_speed < min_speed
        max_speed = abs_speed if abs_speed > max_speed
        Debug.log "cy: #{current_y} ly: #{last_y} d: #{distance} ct: #{current_t} lt: #{last_t} t: #{time} spd: #{speed}"
        # Debug.log "t: #{time} spd: #{speed}"      
      last_move = move
    
    first_y = @moves and touch_page_y @moves.first()
    last_y = @moves and touch_page_y @moves.last()
    distance = last_y - first_y
    first_t = @moves and @moves.first().timeStamp
    last_t = @moves and @moves.last().timeStamp
    time = last_t - first_t
    av_speed = Math.abs distance/time
    # Debug.log "min_spd: #{min_speed}"
    # Debug.log "max_spd: #{max_speed}"
    # Debug.log "av_spd: #{av_speed}"
    # Debug.log "min_time: #{min_time} max_time: #{max_time} av_time: #{times.mean()}"
    # Debug.log "Average of last #{n} speeds = #{@average_last_n_speeds(n)}" for n in [2..20]
    # Debug.log "Momentum in pages = #{@momentum_in_pages_for_exit_speed()}"
    
    
# --------
# Scroller
# --------
# Instantiates a ScrollerTouchHandler on the scroll_el_str element and handles the move_px and move_end it gets from it.
class window.Scroller  
  @instances: {}
  
  constructor: (options={}) -> 
    @scroll_el_str = options.scroll_el_str
    
    @scroll_el = $(@scroll_el_str) 
    $.error "Scroller: requires a scroll_el_str that finds a unique element that is being scrolled." unless @scroll_el.length is 1
    
    @scroll_el_initial_offset = @scroll_el.position().top
    
    @page_el_str = options.page_el_str
    @page_els = $(@page_el_str)
    $.error "Scroller: requires a page_el_string that finds a set of page elements." if @page_els.length is 0
    
    Scroller.instances[@scroll_el_str] = @
    
    @on_stop = options.on_stop
    @on_at_bottom = options.on_at_bottom
    @on_at_top = options.on_at_top
    @before_scroll_to = options.before_scroll_to
    @refresher = options.refresher
    
    touch_handler_options = {
      scroll_el_str: @scroll_el_str,
      transition_running: @transition_running,
      move_px: @move_px,
      move_end: @move_end,
      stop_scrolling: @stop_scrolling,
    }
    @sth = new ScrollerTouchHandler(touch_handler_options)
    @calc_page_positions()
    @setup_transition_end_handler()
    @setup_css_for_scroller()
    @transition_ended()
      
  setup_css_for_scroller: =>
    @scroll_el.css("-webkit-backface-visibility",  "hidden")
    @translate_y(0)
    
  setup_transition_end_handler: =>
    @scroll_el.on('transitionend webkitTransitionEnd', @transition_ended)
    
  transition_started: => @tran_running = true
  
  transition_ended: (e) =>
    # Only look at scroll transitions. There may be others such as like_animation etc.
    return if e and e.target isnt @scroll_el.get(0)
    @tran_running = false
    @on_stop(@page_els[@current_page()]) if @on_stop
    @on_at_bottom() if @on_at_bottom and @current_position() is @last_position
    @on_at_top() if @on_at_top and @current_position() is @first_position
    
  transition_running: => @tran_running
        
  move_pages: (num_pages, px_per_ms) =>
    target_page = @current_page() + num_pages
    target_page += 1 if num_pages < 0  #If you are scrolling up from a page boundary you current_page will already be the previous page after move_px is done.
    target_page = 0 if target_page < 0
    target_page = @last_page if target_page > @last_page
    
    target_position = @page_positions[target_page]
    
    @scroll_to(target_position, px_per_ms)
  
  duration_for_speed: (px_per_ms) =>
    # Defines the feeling of friction and mass. A heavier body starting faster will move longer.
    s = Math.abs px_per_ms
    switch 
      when s < 0.5 then 250
      when s < 1.0 then 500
      when s < 1.25 then 800
      else 1000
      
  move_end: (px_per_ms) =>
    return @end_out_of_bounds() if @out_of_bounds()
    px_per_ms = Math.min(px_per_ms, 3.5)    
    px_per_ms = Math.max(px_per_ms, -3.5)
    duration = @duration_for_speed(px_per_ms)
    distance = Math.floor (duration * px_per_ms)
    position = @current_position() + distance
    px_per_ms *= 0.5
    @scroll_to(@snap_position(position, px_per_ms), Math.abs px_per_ms)
  
  end_out_of_bounds: => 
    if @below_bottom()
      position = @last_position
    else
      position = ( @refresher and @refresher.move_end() ) or @first_position
    @scroll_to(position, 1)
      
  snap_position: (position, direction) =>
    # Dertermine whether to snap to a page boundary and which one to snap to. 
    # Note page boundaries are when a photo_block is lined up with the top of the page. So 
    # snapping works a little differently when you are scrolling up rather than down.
    switch
      when position < @first_position then @first_position
      when position > @last_position then @last_position
      when @page_of_position(position) is @current_page() then position
      when direction < 0 then @page_positions[@page_of_position(position) + 1]
      else @page_positions[@page_of_position(position)]

  # Scroll with speed.
  scroll_to: (target_position, px_per_ms) =>
    # @before_scroll_to() if typeof @before_scroll_to is "function"
    px_per_ms = Math.max(px_per_ms, .05)    
    delta_px = Math.abs(@current_position() - target_position)
    return if delta_px < 10
    duration_ms = Math.floor(delta_px/px_per_ms)
    @transition_started()
    @scroll_el.css("-webkit-transition", "-webkit-transform #{duration_ms}ms cubic-bezier(.02,.02,.32,.92)")
    @translate_y(-target_position) 
  
  scroll_to_top: => @scroll_to(@first_position, 1)

  move_px: (num_px) =>
    target_position = @current_position() + if @out_of_bounds() then Math.floor(num_px*0.5) else Math.floor(num_px*1.3)
    @refresher.move_px(target_position) if @refresher and @above_top()
    set_transition(@scroll_el, "-10s linear")
    @translate_y(-target_position)  
        
  stop_scrolling: => 
    # Note I used to set the transition to -10s to bump the previous transition and execute immediately. This works
    # everywhere but android. You need to set to a small positive number for android like .001s. You cant set to 
    # a small positive number everywhere for jump_to or pan transitions though becuase it is juttery and cuases the 
    # the last scene of the preceding transition to flash.
    if Config.is_android then set_transition(@scroll_el, ".001s linear") else set_transition(@scroll_el, "-10s linear")
    @translate_y(-@current_position())
    # Setting duration to -10 seems to prevent the transitionend event from firing so make it explicit..
    @transition_ended()
      
  jump_to: (position) =>
    # target_page = @page_of_position(position)
    # target_position = @page_positions[target_page]
    # I dont set transition to none here or it will flash the final position of an ongoing transtion.
    # See http://stackoverflow.com/questions/15484242/unable-to-stop-css3-transition-of-transform-by-translate3d
    # for why I set the delay to a negative number rather than 0
    set_transition(@scroll_el, "-10s linear")
    @translate_y(-position)  
    # Setting duration to -10 seems to prevent the transitionend event from firing so make it explicit..
    @transition_ended()
  
  jump_to_top: => @jump_to @first_position
  
  translate_y: (y) =>
    # @scroll_el.css("#{param}", "translate3d(0px,#{y}px, 0px)") for param in ["transform", "-webkit-transform"]
    @scroll_el.get(0).style.webkitTransform = "translate3d(0px,#{y}px, 0px)"
    # Current_position is called here because it blocks after a transform but is cached so that the calling it 
    # again later if a transform hasnt run causes no delay. Since the translate abvoe blocks touch_move events for some 
    # period we might as well get and cache current_position so that when it is needed next for the next touch move 
    # it is ready. This improves the performance for move_px scrolling. See the notes in gallery2_w_iphone.txt.
    @current_position()
  
  scroll_el_modified: => @calc_page_positions()
  
  pages_added: =>
    @page_els = $(@page_el_str)
    @calc_page_positions()
     
  calc_page_positions: =>
    @page_positions = []
    # Note this is now hard wired to look for a positioned frame element as the parent when calc page positions for page_els.
    # not good for general usage of the scroller without the GalleryLoader and GalleryFramePositioner but works for 
    # our special case.
    @page_positions.push $(el).parent().position().top for el in @page_els
    @last_page = @page_els.length - 1
    @first_position = @page_positions.first()
    @calc_last_position()
    
  calc_last_position: =>
    last_page_height = $(@page_els.last()).parent().height()
    last_page_extent_below_window_bottom = Math.max(0, last_page_height - $(window).height())
    # Add a visual padding at the bottom of the page so user feels like there is nothing more.
    last_page_extent_below_window_bottom += 75 if last_page_extent_below_window_bottom > 0 
    @last_position = @scroll_el_initial_offset + @page_positions.last() + last_page_extent_below_window_bottom
      
  below_bottom: => @current_position() > @last_position
  above_top: => @current_position() < @first_position
  out_of_bounds: => @above_top() || @below_bottom()
  
  # Credit to http://stackoverflow.com/questions/4975727/how-do-i-get-the-position-of-an-element-after-css3-translation-in-javascript
  # for this beauty:
  current_position: => -( new WebKitCSSMatrix(window.getComputedStyle(@scroll_el.get(0)).webkitTransform) ).m42
    
  page_of_position: (position) =>
    page = 0
    for pos, n in @page_positions
      page = n
      break if pos > position
    page--
    page = Math.max(0, page)
    
  current_page: => @page_of_position(@current_position())
  
  freeze: => @sth.freeze()
  unfreeze: => @sth.unfreeze()
  pause: => @sth.pause()
  resume: => @sth.resume()

window.print_garf = ->
  r = []
  r.push [window.GARF[n][0] - window.GARF[n-1][0], "#{window.GARF[n-1][1]} -> #{window.GARF[n][1]}"] for n in [1..window.GARF.length-1]
  r
  