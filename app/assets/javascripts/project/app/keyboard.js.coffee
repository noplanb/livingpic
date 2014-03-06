class window.Keyboard
  
  @show: (input_element) => 
    # Note I use the javascript rather than the jquery for focus here becuase it is a little faster and doesnt interfere 
    # as much with animations.
    $.error "Keyboard show requires an input element" unless input_element?
    if input_element instanceof jQuery then input_element.get(0).focus() else input_element.focus()
    @android_show() if Config.is_android_device()
  
  @hide: (input_element) =>
    $.error "Keyboard hide requires an input element" unless input_element?
    if input_element instanceof jQuery then input_element.get(0).blur() else input_element.blur()
    @android_hide() if Config.is_android_device()
  
  
  # ========================
  # = Using Android Plugin =
  # ========================
  @echo: (t) => cordova.exec(@pass, @fail, "Keyboard", "echo", [t])
  
  # Note show wont work unless an input element is already focused.
  @android_show: (t) => cordova.exec(@pass, @fail, "Keyboard", "show", [])
  
  @android_hide: (t) => cordova.exec(@pass, @fail, "Keyboard", "hide", [])
  
  @android_is_showing: (t) => cordova.exec(@pass, @fail, "Keyboard", "isShowing", [])
  
  @pass: (r) => Logger.log "AndroidKeyboard: #{r}"
  
  @fail: (r) => Logger.log "AndroidKeyboard: #{r}"