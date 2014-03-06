# Deprecate when occasions_view.js.coffee is working.
$(document).ready ->
  # Show what we have
  $("#occasions").on "pagebeforeshow", ->
    Logger.log("Rendering the occasions we have")
    OccasionsView.render()
    
  # Then refresh when it comes back from the server
  $("#occasions").on "pageshow", ->
    console.log("Showing occasions page")
    Occasion.refresh(OccasionsView.render)

class window.OccasionsView
  @LIST_ITEM_HTML: "<li>
                     <a href='#'>
                       <img/>
                       <h1 class='occasion_name'/>
                       <p>
                         <span class='occasion_city de-emphasize1'/> &nbsp; 
                         <span class='occasion_date de-emphasize2'/>
                        </p>
                     </a>
                   </li>"
  
  @LIST_HTML: "<ul id='occasions_list' data-role='listview' class='npb-list'></ul>"
  
  @render: (options={}) =>
    occasions = Occasion.all()
    Logger.log("Updating the occasion list page with #{occasions.length} occasions")
    @page =  if options.page? then options.page else $("#occasions")
    content = @page.children(":jqmData(role=content)")
    list = $(OccasionsView.LIST_HTML)

    for occasion in occasions
      @insert_occasion_in_list occasion,list

    content.html(list)
    @page.page()
    $("#occasions_list").listview()
        
  @insert_occasion_in_list: (occasion,list) =>
    el = $(OccasionsView.LIST_ITEM_HTML)
    # Sani, I changed this to go directly to /gallery rather than Config.base_url()/gallery b/c that 
    # would take me to the indicated route, and it seems that's not what you want.  
    el.find("a").bind "click", -> GalleryController.show(occasion)
    # This is for backwards compatibility
    el.find("img").attr("src", if occasion.thumb() then occasion.thumb().thumb_display_url() else Picture.EMPTY_OCCASION_THUMBNAIL_PATH)
    el.find(".occasion_name").html(occasion.name)
    el.find(".occasion_city").html(occasion.city)
    el.find(".occasion_date").html(lp_date_format occasion.start_time)
    list.append(el)
    
            
  