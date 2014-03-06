# MARKED FOR DELETION.
# This was just used when playing with iscroll. It can be deleted when we have our homebrew scroll
# working.

$(document).ready ->
  $("#test_scroll").on "pagebeforeshow", TempGalleryController.before_show
  $("#test_scroll").on "pageshow", TempGalleryController.show
  $(document).on "touchmove", (e) -> e.preventDefault() if current_page() is "test_scroll"

# GalleryScrollHandler
# This hanldler works in conjuction with iScroll. Its purpose is to improve the performance of scrolling for 
# a gallery which consists of a long page with a large number of fullwidth images.
# It improves performance by setting the visibility of images that are outside the viewport to hidden.
# 
# Assumptions and conventions:
#  - page to be scrolled must already be loaded and showing for iscroll to refresh itself properly.
#  - page should have the layout: div(wrapper) -> div(scroller) -> ul(thelist) -> li()
class window.GalleryScrollHandler
  
  # Number of pages that should be on above and below the current page
  @num_on_pages_around: 7
  
  constructor: (params={}) ->
    @iscroll_wrapper = params.iscroll_wrapper || $.error "GalleryScrollHandler requires a iscroll wrapper element."
    # Pass in the number of pages to reduce setup time 
    @num_pages = params.num_pages || $(@iscroll_wrapper).find("li").length
    setTimeout(@setup_iscroll, 0)
    
    @top_on_page = 0
    @bottom_on_page = Math.min(@num_pages-1, 7)
    @last_page = @num_pages-1
    @num_on_pages_around = GalleryScrollHandler.num_on_pages_around
    
    @debug = params.debug || true
    
  debug_log: (msg) =>
    Debug.log msg if @debug
      
  setup_iscroll: => 
    iscroll_options = {
      snap: 'li',
      momentum: true,
      hScrollbar: false,
      onScrollEnd: @scrollend_handler,
      # onBeforeScrollEnd: -> console.log "BeforeScrollEnd",
      # onTouchEnd: -> console.log "TouchEnd"
      vScrollbar: false
    }
    @iscroll = new iScroll(@iscroll_wrapper, iscroll_options) 
  
  scrollend_handler: => 
    @toggle_pages_for(@current_page())
  
  current_page: =>
    # Cant use currPageY because iscroll does not seem to set it properly in the case where
    # a user scrolls quickly then touches to stop scrolling. So calculate it ourselves from 
    # @iscroll.x
    y = @iscroll.y
    page = 0
    for offset, i in @iscroll.pagesY
      page = i
      break if offset <= y
    return page
    
  toggle_pages_for: (current_page) =>
    # @debug_log "Toggle for current_page: #{current_page}"
    for page in @should_be_on(current_page)
      @turn_on_page(page) unless @page_is_on(page)
    
    for page in @is_on_but_should_be_off(current_page)
      @turn_off_page(page)
    
    @reset_pointers(current_page)
    # @debug_log "Expected on pages: #{@on_pages()}"
    # @debug_log "Actual on pages: #{@actual_on_pages()}"
  
  should_be_on: (current_page) => 
    top = Math.max(0, current_page-@num_on_pages_around)
    bottom = Math.min(@last_page, current_page+@num_on_pages_around)
    [top..bottom]
  
  on_pages: => [@top_on_page..@bottom_on_page]
  
  page_is_on: (page) => page in @on_pages()
    
  is_on_but_should_be_off: (current_page) => @on_pages().diff @should_be_on(current_page)
    
  reset_pointers: (current_page) => 
    @top_on_page = Math.max(0, current_page - @num_on_pages_around)
    @bottom_on_page = Math.min(@last_page, current_page + @num_on_pages_around)
  
  turn_on_page: (page) => 
    # @debug_log "Turn on: #{page}"
    @image_for_page(page).css("visibility", "visible")
    
  turn_off_page: (page) => 
    # @debug_log "Turn off: #{page}"
    @image_for_page(page).css("visibility", "hidden")
  
  image_for_page: (page) => $(@iscroll_wrapper).find("img.#{page}")
  
  actual_on_pages: =>
    result = []
    for img in $(@iscroll_wrapper).find("img")
      result.push $(img).attr("class") if $(img).css("visibility") is "visible"
    result
    
    
    
    
# This sets up the dummy gallery in #test_scroll in testpages for testing for now. 
class window.TempGalleryController
  @page: "#test_scroll"
    
  @before_show: => SetupTestScrollPage.setup(@page)
  
  @show: => @gsh = new GalleryScrollHandler(iscroll_wrapper: $("#{@page} .wrapper").get(0))
  
  