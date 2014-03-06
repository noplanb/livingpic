# ==============
# = InstaClick =
# ==============
#  Add event listeners for the elements with data-instaclick set.

$(document).ready ->
  InstaClick.add_handlers()
  
class window.InstaClick
  
  @add_handlers: =>
    els = $("[data-instaclick]")
    @add_handler(el) for el in els
    
  @add_handler: (el) =>
    script = $(el).data().instaclick
    allow_propagation = $(el).data().allow_propagation
    allow_default = $(el).data().allow_allow_default
    funct_name = "#{$(el).attr.id}_oninstaclick"
    
    function_contents  = "" 
    function_contents += "e.preventDefault();" unless allow_default 
    function_contents += "e.stopPropagation();" unless allow_propagation
    function_contents += script

    InstaClick[funct_name] = new Function("e", function_contents)
    
    event_type = if Config.is_running_in_browser() then "click" else "touchstart"
    # Note I set use_capture here to catch as quickly as possible and make sure no other code hanging anywhere on the 
    # DOM jquery_mobile, fastclick or otherwise runs due to this event.
    $(el).get(0).addEventListener(event_type, InstaClick[funct_name], true)
    