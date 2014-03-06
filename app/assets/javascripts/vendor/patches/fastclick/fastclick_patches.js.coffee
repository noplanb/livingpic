# FastClick.needsClick patched so that it looks at the parents of an element 
FastClick.prototype.needsClick = (target) ->
  'use strict';
  nodeName = target.nodeName.toLowerCase();
  
  if nodeName is 'button' or nodeName is 'input'
    
    # File inputs need real clicks on iOS 6 due to a browser bug (issue #68)
    # Don't send a synthetic click to disabled inputs (issue #62)
    if (this.deviceIsIOS and target.type is 'file') or target.disabled
      # Debug.log "This device test"
      return true
      
  else if nodeName is 'label' or nodeName is 'video'
    return true
    
    # PATCH is HERE:
    # Old code
    # return (/\bneedsclick\b/).test(target.className); 
       
  # New code
  parents = $(target).add $(target).parents()
  for element in parents 
    return true if $(element).hasClass("needsclick")
  return false