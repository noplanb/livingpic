# ==================
# = SelectorButton =
# ==================
$(document).ready -> SelectorButton.attach()

class window.SelectorButton
  
  @attach: => 
    event_type = if Config.is_running_in_browser() then "click" else "touchstart"
    for button in $(".selector_button")
      button.addEventListener(event_type, (new SelectorButton button).click, false)      
  
  constructor: (button) ->
    @button = button
  
  click: (e) =>
    e.stopPropagation()
    e.preventDefault()
    orig = e.originalTarget || e.srcElement
    $(orig).siblings().removeClass "selected"
    $(orig).addClass "selected"
  

# ================
# = EditTextarea =
# ================
#  Widget used for editing and posting comments, captions etc.
$(document).ready -> EditTextarea.attach()

class window.EditTextarea
  
  @instances = {}
  
  @attach: => 
    new EditTextarea $(widget).attr("id") for widget in $("[data-widget='edit_textarea']")
    @instances
  
  @instance: (id) => @instances[id]
    
  constructor: (widget_id) ->
    EditTextarea.instances[widget_id] = @
    @widget_id = widget_id
    @widget = $("##{@widget_id}")
    @textarea = $("##{@widget_id} textarea")
    @post_click = new Function("text","object", @widget.data().post_click)
    @cancel_click = new Function("object", @widget.data().cancel_click)

  edit: (text, object) =>
    @object = object
    @textarea.val(text) if text
    @show()
  
  post: => 
    text = @textarea.val().trim()
    return @cancel() if text.is_blank()

    @hide()
    @reset()
    @post_click(text, @object)

  cancel: => 
    @hide()
    @reset()
    @cancel_click(@object)
  
  show: => 
    @widget.off('transitionend webkitTransitionEnd')
    @widget.on('transitionend webkitTransitionEnd', @shown)    
    set_transition(@widget, "300ms linear")
    @widget.css transform: "translate3d(0px,0px,0px)"
  
  shown: => 
    Keyboard.show @textarea
  
  hide: =>
    # Using native js for speed. 
    # Note the obvious thing would be to set visibility to hidden and visible for content here. However
    # doing so is slow and cuases the page to come back flickering and in sections when set backt o visible. Using opacity 
    # to 0 and 100 is much cleaner. I believe this is because opacity acts directly on the content layer that is currently in the gpu
    # whereas visibility cause it to be reloaded there.
    # 
    # Note also i use a translate for new comment block rather than changing its opaciity. It may be a bit faster as it might not think it needs
    # to composite two layers. But I may be wrong and the translate may be the same as toggling opacity from 1 to 0
    set_transition(@widget, "200ms linear")
    @widget.css transform: "translate3d(0px,-160px,0px)"
    @widget.off('transitionend webkitTransitionEnd')
    @widget.on('transitionend webkitTransitionEnd', @hidden) 
  
  hidden: =>   
    Keyboard.hide @textarea

  reset: => @textarea.val("")
  