# =======================
# = OccasionsController =
# =======================
# The controller and view render for the new occasions page. Delete occasions_page.js.coffee when this is working
class window.OccasionsController
  @occasions_page_id: "occasions2"
  
  @show: =>
    Logger.log("Showing the occasions we have")
    Pager.change_page(@occasions_page_id)
    # When occasions page is long rendering each time you go back to makes it feel sluggish and juttery.
    # so only render if it is stale.
    OccasionsView2.render() if @occasions_view_is_stale()
    @refresh_from_server()
    @check_for_broken_background_photo_links()
  
  @refresh_from_server: =>
    Occasion.refresh(OccasionsView2.render)
    Pager.change_page(@occasions_page_id)
  
  @occasions_view_is_stale: => @num_occasions_is_stale() or @people_or_pics_are_stale()
  
  @num_occasions_is_stale: => $("#occasions2 .content").children().length isnt Occasion.all().length
  
  @people_or_pics_are_stale: => 
    disp_occasions = []
    for occ in $("#occasions2 .content").children()
      o = {}
      o.id = $(occ).data().occasion_id
      o.name = $(occ).find(".title").html()
      o.num_participants = parseInt $(occ).find(".people .number").html()
      o.num_photos = parseInt $(occ).find(".pics .number").html()
      disp_occasions.push o
      
    for disp_occ in disp_occasions
      occ = Occasion.find(disp_occ.id)
      unless occ
        Logger.log "ERROR: OccasionController.people_or_pics_are_stale: Expecting to find an occasion for id: #{disp_occ.id}"
        return true
      return true if occ.num_participants() isnt disp_occ.num_participants
      return true if occ.num_photos() isnt disp_occ.num_photos
    
    return false

  @check_for_broken_background_photo_links: =>
    for o in Occasion.all()
      p = o.thumb() || o.photos[0]
      p and p.fix_thumb_display_url_if_broken(@broken_photo_link_fixed)
  
  @broken_photo_link_fixed: => 
    Logger.log("OccasionsController: broken photo link was fixed rendering again.")
    OccasionsView2.reload_thumbs()
  
# ==================
# = OccasionsView2 =
# ================== 
class window.OccasionsView2
  
  @render: => 
    $("#occasions2 .content").html @occasion_blocks()
  
  @occasion_blocks: => 
    html = ""
    html += @occasion_block o for o in Occasion.all()
    html
  
  @thumb_for_occasion: (occasion) =>
    occasion = Occasion.normalize_to_object(occasion)
    if occasion.thumb() 
      thumb =  occasion.thumb().thumb_display_url() 
    else if occasion.photos.length == 0 
      thumb = Picture.EMPTY_OCCASION_THUMBNAIL_PATH 
    else  
      thumb = occasion.photos[0].thumb_display_url()
      # FF: Not sure why I had this at one point....
      # thumb = Picture.LOADING_THUMB_PATH 
    
  @occasion_block: (occasion) => 
    thumb = @thumb_for_occasion(occasion)
    date = m_y_date_format occasion.start_time
    num_people = occasion.num_participants()
    people = "<span class='number'>#{num_people}</span>" + if num_people is 1 then " person" else " people"
    num_pics = occasion.photos.length
    pics = "<span class='number'>#{num_pics}</span>" + if num_pics is 1 then " pic" else " pics"
    """
    <div class="occasion #{occasion.id}" data-occasion_id="#{occasion.id}" onclick="GalleryController2.show(#{occasion.id})">
      <div class="photo" style="background-image: url('#{thumb}')" data-photo_id="#{thumb.id}"></div>
      <div class="text">
        <div class="title">#{occasion.display_name()}</div>
        <div class="sub_title">
          <div class="city_date"><span class="city">#{occasion.city}</span><span class="date">#{date}</span></div>
          <div class="people_pics"><span class="people">#{people}</span> &nbsp; <span class="pics">#{pics}</span></div>
        </div>
      </div>
    </div>
    """

  @reload_thumbs: =>
    for occasion_div in $("#occasions2 .occasion")
      occasion_id = $(occasion_div).data().occasion_id
      photo_div = $(occasion_div).find(".photo")
      thumb = @thumb_for_occasion(occasion_id)
      $(photo_div).css("background-image", "url('#{thumb}')")
    
      

# GARF - duplicate code here with occasion_for_pic
# TODO REFACTOR!
# =========================
# = NewOccasionController =
# =========================
class window.NewOccasionController2
  
  @show: => 
    $("#new_occasion .new_occasion_submit").off "click"
    $("#new_occasion .new_occasion_submit").on("click", $.debounce(2000, true, @post))
    NewOccasionView2.render()
    
  @post: => @try_save_occasion_to_server() if @set_current_occasion_from_form()

  @set_current_occasion_from_form: =>
    id = null
    name = $("#new_occasion .new_occasion_name").val().trim()
    if name is ""
      alert "Please enter an album name." 
      return false
    if Occasion.find_by_name name
      alert "You already have an album named #{name}"
      return false
    GeoLocation.get_location()
    set_current_occasion new Occasion {name: name, id: id}
    return true

  @try_save_occasion_to_server: =>
    LoaderSpinner.show_spinner()
    current_occasion().save_to_server({success: @new_occasion_success, error: @new_occasion_error})

  @new_occasion_success: (response) =>
    # Udate the id in the current_occasion
    Occasion.add(current_occasion())
    @occasion_confirmed()

  @new_occasion_error: (jqXHR, textStatus, errorThrown) => Pager.change_page "#network_error"

  # Start the upload and go to show the gallery
  @occasion_confirmed: =>
    console.log("Created new occasion: "+current_occasion().id)
    FlashNotice.flash("Album created. Well done. Now add participants and photos.")
    @show_gallery()

  @show_gallery: => GalleryController2.show_current()   

# ===================
# = NewOccasionView =
# ===================
class window.NewOccasionView2
  
  @render: => 
    $("#new_occasion .new_occasion_name").val("")
    Pager.change_page "new_occasion"
