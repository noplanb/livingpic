# ================
# = test_country =
# ================
class window.TestCountryController
  @show: => 
    new PhoneEntryFieldController("pwc1")
    new PhoneEntryFieldController("pwc2")
    Pager.change_page "test_country"    

# =================
# = test_debounce =
# =================
class window.TestDebounce
  
  @show: => 
    @inline_click = $.debounce(2000, true, @inline_incr)
    @setup()
    Pager.change_page "test_debounce"
    
  @setup: =>
    $("#test_debounce .normal_button").on "click", @normal_click
    $("#test_debounce .debounced_button").on "click", $.debounce(2000, true, @debounced_click)
    $("#test_debounce .throttled_button").on "click", $.throttle(2000, @throttled_click)
  
  @normal_click: => @increment $("#test_debounce .normal_result")
  @debounced_click: => @increment $("#test_debounce .debounced_result")
  @throttled_click: => @increment $("#test_debounce .throttled_result")
  @inline_incr: (text) => 
    @increment $("#test_debounce .inline_result")
    console.log text
  
  @increment: (element) =>
    n = parseInt $(element).html()
    $(element).html(n+1)

# ==================
# = TestClickDelay =
# ==================
class window.TestClickDelay
  
  @show: => 
    @add_event_handlers @tst_btns()
    Pager.change_page "test_click_delay"
  
  @t0: null
  
  @tst_btns: => $("#test_click_delay .test_button")
  
  @add_event_handlers: (els) ->
    els.off "touchstart", TestClickDelay.test_event
    els.off "touchend", TestClickDelay.test_event
    els.off "tap", TestClickDelay.test_event
    els.off "vclick", TestClickDelay.test_event
    els.off "click", TestClickDelay.test_event
    
    els.on "touchstart", TestClickDelay.test_event
    els.on "touchend", TestClickDelay.test_event
    els.on "tap", TestClickDelay.test_event
    els.on "vclick", TestClickDelay.test_event
    els.on "click", TestClickDelay.test_event
  
  @get_delay: () ->
    if TestClickDelay.t0? and (new Date) - TestClickDelay.t0 < 1000
      delay = (new Date) - TestClickDelay.t0
    else
      TestClickDelay.t0 = new Date
      delay = 0
    
    return delay
  
  @html_onclick: (target) ->
    e = {target: target, type: "HTML onclick"}
    TestClickDelay.test_event e
    
  @test_event: (e) -> 
    delay = TestClickDelay.get_delay()
    txt = "#{e.type.toUpperCase()}: #{delay} [#{$(e.target).attr 'class'}]\n"
    # console.log txt
    $("#test_click_delay .timing").html "" if delay is 0
    $("#test_click_delay .timing").append txt
    # if e.type is "vclick"
    #   console.log "stoppying propagation of #{e.type}"
    #   e.stopPropagation()
    # if e.type is "touchstart"
    #   console.log "triggering a click due to #{e.type}"
    #   $("#test_click_delay .test_button").trigger "click"

# =======================
# = SetupTestScrollPage =
# =======================
class window.SetupTestScrollPage
  @setup: (page, num_on=8, num_images=20, no_text=false) =>
    @image_urls = Photo.all().first(num_images).map (p) -> p.thumb_display_url()
    @page = page
    @num_on = num_on
    @download_all_photos()
    @insert_images()
    @set_image_heights()
    @insert_text() unless no_text

  @insert_images: =>
    img_tags = []
    for image, i in @image_urls
      img_tags.push $("<li class='pic_block #{i}'><div class='pic #{i}'><img class='#{i}' src='#{image}' style='width:100%; visibility:#{if i<@num_on then "visible" else "hidden"}'></div><div>#{i}</div></li>")
    $("#{@page} .thelist").html img_tags

  @insert_text: =>
    $("#{@page} .pic_block").append("Caption is here<br/>Comment1: blah blah blah blah<br/>Comment2: bloh bloh bloh bloh<br/>")
    $("#{@page} .pic_block").append("Comment3: blah blah blah blah<br/>Comment4: bloh bloh bloh bloh<br/>")

  @set_image_heights: =>
    window_width = $(window).outerWidth() + 20
    image_height = Math.floor(3*window_width/4)
    $("#{@page} .pic").css("height", "#{image_height}px")
  
  # Hack to test with all local photos
  @download_all_photos: => 
    return if Config.is_running_in_browser()
    @download_next_photo()
    @download_next_thumb()

  @download_next_photo: => 
    non_local_photos = Photo.all().filter (p) -> not p.has_local_image()
    console.log "#{non_local_photos.length} non_local photos"
    next_photo = non_local_photos.first()
    if next_photo
      console.log "Downloading photo #{next_photo.id}"
      next_photo.download(SetupTestScrollPage.download_next_photo)
    else
      console.log "Done downloading photos"

  @download_next_thumb: => 
    non_local_thumbs = Photo.all().filter (p) -> not p.has_local_thumb()
    console.log "#{non_local_thumbs.length} non_local thumbs"
    next_thumb = non_local_thumbs.first()
    if next_thumb
      console.log "Downloading thumb #{next_thumb.id}"
      next_thumb.download_thumb(SetupTestScrollPage.download_next_thumb)
    else
      console.log "Done downloading thumbs"


# ===================
# = TestCustomEvent =
# ===================
class window.TestCustomEvent
  
  @show: => Pager.change_page "test_custom_event"
  
  @fire: =>
    Debug.log "Fire"
    console.profile()
    # $("#test_custom_event .target").get(0).addEventListener("myevent", @received, false)
    # ev = new CustomEvent( "myevent",  { detail: {message: "Hello World!"}, bubbles: true, cancelable: true} )  
    $("#test_custom_event .target").trigger("click")
  
  @received: => 
    console.profileEnd()
    Debug.log "Received"

# ====================
# = TestParentOffset =
# ====================
class window.TestParentOffset
  
  @show: =>
    @a = $("#test_parent_offset .a")
    @b = $("#test_parent_offset .b")
    @c = $("#test_parent_offset .c")
    @d = $("#test_parent_offset .d")
    
    style = position:"relative", top:"50px", left:"50px", right:"50px", bottom:"50px"
    @a.css extend(style, border:"1px solid red")
    @b.css extend(style, border:"1px solid green")
    @c.css extend(style, border:"1px solid blue")
    @d.css extend(style, border:"1px solid black")
    
    Pager.change_page "test_parent_offset"
    
    r = ""
    r += "#{i}: offset:#{el.offset().top} position:#{el.position().top}\n" for el,i in [@a,@b,@c,@d]
    
    $("#test_parent_offset pre").html r
    
# ===================
# = TestImgReload =
# =================== 
class window.TestImgReload
  
  @show: => Pager.change_page "test_image_reload"
  
  @low_res: => $("#test_image_reload img").attr("src", Photo.first().thumb_display_url())
  @hi_res: => $("#test_image_reload img").attr("src", Photo.first().display_url())

# ===================
# = TestTouchTarget =
# ===================
class window.TestTouchTarget
  
  @show: => 
    @page = $("#test_touch_target")
    @page.find(".targ").css {
      width:"45%"
      height:"100px"
      border:"1px solid red"
      position: "absolute"
    }
    @page.find(".results").css {
      position: "absolute"
      top: "55px"
      height:"100px"
      width:"50%"
      right:"0"
      border: "1px solid blue"
      padding: "2px"
      "font-size": "10px"
    }
    @page.find(".content").css {
      top: "175px"
      overflow: "visible"
    }
    
    Pager.change_page "test_touch_target"
  
  @handle_event: (e) =>
    e.stopPropagation()
    e.preventDefault()
    @log_event(e)
    @show_box_offsets()
    
  @log_event: (e) =>
    r = ""
    r += "EventType: #{e.type}\n"
    r += "Target: #{e.target.className}\n"
    r += "PageXY: #{e.pageX}, #{e.pageY}\n"
    r += "Tchs0.pageXY: #{e.touches and e.touches[0].pageX}, #{e.touches and e.touches[0].pageY}\n"
    @page.find("pre.fixed").html r
  
  @show_box_offsets: =>
    for el in @page.find(".in_box").get()
      box = $(el).parent()
      r = ""
      r += "Offset: #{box.offset().left}, #{box.offset().top}\n"
      $(el).html r
 
  @tr: (d) => 
    @page.find(".content").css transform: "translateY(#{d}px)"
   
# =======================
# = TestAndroidKeyboard =
# =======================
#  Focus doesnt seem to make it come up on android.
class window.TestAndroidKeyboard
  @show: =>
    Pager.change_page "test_android_keyboard"
    
# ======================
# = TestStopTransition =
# ======================
# Cant seem to make android stop a transition
# Found that you cant set a transition to 0s or to a negative number to stop the previous transtion. You just need to set it to 
# a very small number.
class window.TestStopTransition
  @show: =>
    Pager.change_page "test_stop_transition"
  
  @move: => 
    $("#test_t_stop").css("-webkit-transition", "all 200s")
    $("#test_t_stop").css("-webkit-transform", "translate3d(0px, 500px,  0px)")
  
  @stop: =>
    $("#test_t_stop").css("-webkit-transition", "all .01s")
    $("#test_t_stop").css("-webkit-transform", "translate3d(0px, 0px,  0px)")

# ========================
# = TestPhotoOrientation =
# ========================
class window.TestPhotoOrientation
  @page_id = "test_photo_orientation"
  @show: =>
    Pager.change_page @page_id
    @get_photos()
  
  @get_photos: => 
    $.ajax {
      dataType: "json"
      url: Config.base_url() +  "/photos/test_orientation_json"
      async: false;
      success: (response) =>
        TestPhotoOrientation.photos = response
        TestPhotoOrientation.insert_photos()
      error: (jqXHR, textStatus, errorThrown) =>
        $.error()
    } 
    
  @insert_photos: =>
    photo_html = ""
    photo.display_url = Config.base_url() + photo.url for photo in @photos
    photo_html += @photo_block_html(photo,i) for photo, i in @photos
    $("##{@page_id} .photo_box").html photo_html
    
  @photo_block_html: (photo,index) => 
    """
    <h3>#{photo.name.capitalize_words()}</h3>
    Orientation: #{photo.orientation},  W: #{photo.width},  H: #{photo.height}<br/><br/><br/>
    Background Image<br/><br/>
    <div id="tpo_thm_#{index}" class="thumb" data-index="#{index}" style="background-image: url(#{photo.display_url});" onclick="TestPhotoOrientation.zoom(this)"></div><br/><br/><br/>
    Image<br/><br/>
    <img id="tpo_img_#{index}" class="image" data-index="#{index}" src="#{photo.display_url}" onclick="TestPhotoOrientation.zoom(this)"/><br/><br/><br/>
    """
  
  @zoom: (photo_el) =>
    i = $(photo_el).data().index
    photo = @photos[i]
    @zoomer = new Zoomer(photo_el, {
      src: photo.display_url
      page: "##{@page_id}"
      photo: photo
    })
    
  @clear: => 
    $("#test_photo_orientation .photo_box").html("")
  
  
# =============================
# = TestAndroidAlbumInterface =
# =============================
class window.TestAndroidAI
  
  @show: => 
    


    