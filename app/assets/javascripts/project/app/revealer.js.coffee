# ============
# = Revealer =
# ============
class window.Revealer
  
  @margin = 45
  
  @instance: (page, options={}) ->
    Revealer.instances ||= {}
    if Revealer.instances[page] then Revealer.instances[page] else new Revealer(page, options)
    
  constructor: (page, options={}) ->
    Revealer.instances ||= {}
    Revealer.instances[page] = @
    
    @before_reveal = options.before_reveal
    @after_hide = options.after_hide
    
    @cover = $("#{page} .reveal.rev_cover")
    @left = $("#{page} .reveal.rev_left")
    @right = $("#{page} .reveal.rev_right")
    # @cover.css("-webkit-transition", "-webkit-transform 1000ms cubic-bezier(.02,.02,.32,.92)")
    set_transition(@cover, "250ms cubic-bezier(.02,.02,.32,.92)")
    @slide_amount = window.innerWidth - Revealer.margin
  
  reveal: (direction) => 
    @before_reveal() if typeof @before_reveal is "function"
    factor = if direction is "right" then -1 else 1
    if direction is "right" then @right.scrollTop(0) else @left.scrollTop(0)
    amount = @slide_amount * factor
    @cover.css transform: "translateX(#{amount}px)"
    @revealed = true
    @add_touch_handler()
  
  hide: => 
    @revealed = false
    @cover.css transform: "translateX(0px)"
    @after_hide() if typeof @after_hide is "function"
    
  hide_end: (ev) => 
    # We should only act on an event which causes hide_end if hide() has been executed first we can get a mouse_up here due to the
    # first click on the people button which caused this page to be revealed and we want to ignore that one.
    return if @revealed
    
    ev.stopPropagation() if ev
    ev.preventDefault() if ev
    @after_hide() if typeof @after_hide is "function"
    @remove_touch_handler()
  
  toggle: (direction) => if @revealed then @hide() else @reveal direction
  
  add_touch_handler: => 
    # Note we want the touchstart in the bubble up phase so a click on the button that causes a reveal in the header of the
    # cover page takes presidence.
    @cover.get(0).addEventListener("touchstart", @hide, false)
    # Note we want touch end in the capture phase so it takes presidence over any touchend listener below it in the dom.
    @cover.get(0).addEventListener("touchend", @hide_end, true)
    
  remove_touch_handler: => 
    @cover.get(0).removeEventListener("touchstart", @hide, false)
    @cover.get(0).removeEventListener("touchend", @hide_end, true)
     
    