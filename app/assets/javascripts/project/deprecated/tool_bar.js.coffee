$(document).ready -> new ToolBarHandler

# Make it so toolbars on certain pages dont auto hide.
class window.ToolBarHandler
  @ids_of_pages_with_no_hide_tool_bars: ["gallery", "occasions"]
    
  constructor: () ->
    console.log "ToolBarHandler: Manually setting padding for pages: #{$.toSentence ToolBarHandler.ids_of_pages_with_no_hide_tool_bars}"
   
    pages = @find_pages()
    headers = @find_headers(pages)
    footers = @find_footers(pages)
    tool_bars = headers.add footers
    
    @never_hide(tool_bars)
    @disable_update_page_pading(tool_bars)
    @set_page_padding(pages)
    
        
  never_hide: (tool_bars) ->
  # Make our toolbars never hide
    $(tool_bars).fixedtoolbar({ tapToggle: false })
  
  disable_update_page_pading: (tool_bars) ->
    # Do not have jqm automatically update the padding for the page containing tool bars.
    # For some reason auto update of page padding worked on firefox but would not work on android or iphone.
    # It never set the padding for the page containing the toolbars so the toolbars would cover the content.
    # Per the suggestion here: http://api.jquerymobile.com/fixedtoolbar/#option-updatePagePadding
    # we disable updatePagePadding and manually set the padding for the pages containing toolbars.
    $(tool_bars).fixedtoolbar({ updatePagePadding: false })
        
  set_page_padding: (pages) ->
    for page in pages
      $(page).css("padding-top", "46px")
      $(page).css("padding-bottom", "46px")

  find_pages: ->
    pages = $()
    for id in ToolBarHandler.ids_of_pages_with_no_hide_tool_bars
      pages = $(pages).add $("##{id}") 
    pages

  find_headers: (pages) ->
    headers = $()
    for page in pages
      headers = $(headers).add $(page).find("[data-role=header][data-position=fixed]") 
    headers

  find_footers: (pages) ->
    footers = $()
    for page in pages
      footers = $(footers).add $(page).find("[data-role=footer][data-position=fixed]") 
    footers

