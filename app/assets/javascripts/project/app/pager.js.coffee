# =========
# = Pager =
# =========
# Changes pages without jqm for performance reasons. See pager.txt for some perf research. 

class window.Pager
  
  @change_page: (page) =>
    return unless page
    el = document.getElementById(page)
    $(el).trigger 'npb_pagebeforeshow', page
    @current_page ||= "splash" 
    return if page is @current_page
    @page_off(@current_page) if @current_page
    @page_on(page)
    $(el).trigger 'npb_pageshow', page
    @previous_page = @current_page
    @current_page = page
    
  @page_off: (page) => document.getElementById(page).style.display = "none"      
  
  @page_on: (page) => document.getElementById(page).style.display = "block"
  
  @back: => @change_page @previous_page
  
  @current_page_el: =>
    $("#"+@current_page)

# Convenience method
window.current_page = -> Pager.current_page

