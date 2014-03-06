$(document).ready ->
  $.event.special.swipe.horizontalDistanceThreshold = 130;
  $("#pic_detail").on "swiperight", Carousel.display_prev_photo
  $("#pic_detail").on "swipeleft", Carousel.display_next_photo

  # To get around a bug in JQM for allowsamepagetransitions that cuases the page to disappear
  # after the transition. See: http://forum.jquery.com/topic/changepage-allowsamepagetransition-true-displays-blank-page
  $('#pic_detail').on 'pageshow', -> 
    $('#pic_detail').addClass('ui-page-active');
    $('#pic_detail').trigger 'updatelayout'
    $("#pic_detail [data-position='fixed']").fixedtoolbar('hide');

# This is the top-level handler for the carousel view of the photos.  Ideally, it's the only
# "Global" that should be called in the views, etc.  
class window.Carousel
  
  @current_photo: null

  @display_photo = (photo) => 
    Logger.log "displaying photo[#{photo and photo.id}] :: in_new_record:#{photo and photo.is_new_record()}"
    if photo and not photo.is_new_record()
      $.mobile.changePage("#pic_detail")
      @render_pic_detail_page photo
    else
      $.mobile.changePage("#local_pic_dialog")
  
  @display_next_photo: =>
    @render_pic_detail_page GalleryHandler.INSTANCE.next_img(@current_photo.photo)
    $.mobile.changePage("#pic_detail", {allowSamePageTransition:true, transition:"slide", reverse:false})
    
  @display_prev_photo: => 
    @render_pic_detail_page GalleryHandler.INSTANCE.prev_img(@current_photo.photo)
    $.mobile.changePage("#pic_detail", {allowSamePageTransition:true, transition:"slide", reverse:true})
  
  @render_pic_detail_page = (photo) =>
    Logger.log("rendering page for photo #{photo.id}: " + if photo.has_local_image() then "local" else "remote")
    @current_photo = new PhotoView(photo)
    @current_photo.render()
    
  @exit: =>
    if @current_photo 
      GalleryController.show(@current_photo.photo.occasion_id)

  
# ===================
# = PhotoView       =
# ===================

class window.PhotoView
  
  @INSTANCE = null
  
  constructor: (photo) -> 
    PhotoView.INSTANCE = @
    @photo = photo
    @occasion = Occasion.find(@photo.occasion_id)
    @summary_view = new CommentsLikesStatsView(@photo,$("#pic_detail .comments_likes"))
    @like_handler = new LikeHandler(@photo,@update)
    @comment_handler = new CommentHandler(@photo,@update)
    @prepare_pic_container()

  render: =>
    @render_head()
    @render_pic()
    @summary_view.render()
    @like_handler.render()
    @comment_handler.render()
    # stats_panel = new CommentsLikesStatsView(@photo,$("#pic_detail .comments_likes"))
    # stats_panel.render()
    # new CommentHandler(@photo,stats_panel)
    # (new LikeHandler(@photo,stats_panel)).render()
    
  render_head: =>
    $("#pic_detail .pic_id").html(@photo.id)
    $("#pic_detail .occasion_name").html(@occasion.name)
    $("#pic_detail .occasion_city").html(@occasion.city)
    $("#pic_detail .occasion_date").html(lp_date_format @occasion.start_time)
    $("#pic_detail .creator").html "#{@photo.creator.first_name} #{@photo.creator.last_name}"
    $("#pic_detail .caption_box").html $("<div class='caption'>#{if @photo.caption then @photo.caption else ""}</div>")    
  
  prepare_pic_container: =>
    $("#pic_detail .pic").css("min-height", "200px")
    
  render_pic: =>
    pic = $("<img src='#{@photo.display_url()}'/>")
    pic.on "load", @pic_load_event_handler
    pic.on "click", @pic_click_event_handler
    $("#pic_detail .pic").html pic
    # Load the zoomed photo at the same time
    $("#pic_zoom .pic").attr("src", @photo.display_url())
  
  pic_click_event_handler: (event) =>
    # Debug.log "pic clicked"
    $.mobile.changePage "#pic_zoom"
    
  # Allows panoramas to display properly when they load
  pic_load_event_handler: (event) =>
    $("#pic_detail .pic").css("min-height", "0px")
  
  # either the comments or the likes were updated
  update: =>
    @summary_view.render()
    @comment_handler.render()
    @like_handler.render()
    
  like: ->
    @like_handler.like()

  save_new_comment: ->
    @comment_handler.save_new_comment()

  jump_to_comments: ->
    @comment_handler.jump_to_comments()

# ==============
# = LikeHandler =
# ==============
class window.LikeHandler

  @INSTANCE: null
  @MAX_NAMES_LENGTH = 20

  constructor: (photo,on_update) ->
    LikeHandler.INSTANCE = @
    @photo = photo
    @on_update = on_update
  
  render: ->
    @render_likers(@constructor.MAX_NAMES_LENGTH)
    if @photo.liked_by_user(current_user())
      @render_liked()
    else
      @render_like_button() 

  # If the user likes the button, register it
  like: =>
    @photo.likes++
    if @photo.likers
      @photo.likers.unshift(current_user())
    # In case the connectivity is bad, we go ahead and update the liked count
    @render_liked()
    @on_update() if @on_update
    NetworkHandler.instance({
      url: Config.base_url() + "/photos/like/#{@photo.id}",
      type: "POST",
      dataType: "json",
      retry_count: 0,
      success: (response) =>
        @photo.likers = response
        @photo.likes = @photo.likers.length
        @photo.save();
        # @render_liked()
        @on_update() if @on_update
      error: -> Logger.log "Error sending like."
    }).run()
  
  # This is for after the user has indicated that he likes the item
  render_liked: =>
    likes = (new LikesSummaryView(@photo)).html()
    $("#pic_detail .like_status").html likes
    $("#pic_detail .like_button").hide()
    $("#pic_detail .like_status").show()

  # This allows the user to indicate that he likes the item - should probably only be called
  # when the user is allowed to like the item (i.e. hasn't already liked it)
  render_like_button: =>
    # likes = (new LikesSummaryView(@photo)).html()
    # $("#pic_detail .like_status").html likes
    $("#pic_detail .like_status").hide()
    $("#pic_detail .like_button").show()

  liker_names: =>
    other_liker_names = []
    if @photo.likers instanceof Array 
      # first check if it includes the current_user:
      other_likers = (liker for liker in @photo.likers when liker.id != current_user_id())
      other_liker_names = other_likers.map( (user) -> first_and_last_initial(user))
      if @photo.liked_by_user(current_user())
        other_liker_names.unshift("You")

    return other_liker_names
      

  render_likers: (max=1000) =>
    ln = @liker_names()
    names = ln.to_sentence()
    if names is ""
      $(".likers").hide()
    else 
      if names.length > max
        last_comma = names[0...max].lastIndexOf(',')
        if last_comma < 0 
          names = "<span class='pseudo_link'>#{ln.length} people</span>"  
        else
          names = names[0...last_comma]
          n = ln.length - names.split(',').length 
          names = names + " <span class='pseudo_link'>and #{n} others</span>"  
        $(".likers .names").on("click",@show_all_likers)  
      $(".likers .names").html names
      $(".likers").show()


  show_all_likers: =>
    @render_likers()
  
    

# ===================
# = KeyboardHandler =
# ===================
# Could not get this to work on android 4.2
class window.KeyBoardHandler
  @hide_keyboard: (element) => 
    element.attr('readonly', 'readonly') #Force keyboard to hide on input field.
    element.attr('disabled', 'true') if element.is("textarea")    #Force keyboard to hide on textarea field.
    setTimeout( ->
      element.blur()                   #actually close the keyboard
      # Remove readonly attribute after keyboard is hidden.
      element.removeAttr('readonly')
      element.removeAttr('disabled')
    , 100)
        
$(document).ready ->
  CommentHandler.TEXT_ENTRY_FIELD = $("#pic_detail .new_comment textarea")

  CommentHandler.TEXT_ENTRY_FIELD.bind "keyup", (event) ->
    CommentHandler.new_comment_keyup(event)


# ==================
# = CommentHandler =
# ==================

  
class window.CommentHandler
  
  @INSTANCE: null
  @TEXT_ENTRY_FIELD: null
  
  @new_comment_keyup: (event) =>
    @TEXT_ENTRY_FIELD.removeClass("blurred")
        
  @new_comment_value: =>
    @TEXT_ENTRY_FIELD.val().trim()

  @reset_entry_field: =>
    @TEXT_ENTRY_FIELD.addClass("blurred").val("").css("height", "50px")
    # @TEXT_ENTRY_FIELD.val("")
    # @TEXT_ENTRY_FIELD.css("height", "50px")

  constructor: (photo,on_update) ->
    CommentHandler.INSTANCE = @
    @photo = photo
    @on_update = on_update

  render: =>
    @render_new_comment_field()
    @render_comments()
    
  render_comments: => 
    $("#pic_detail .comments").html ( new CommentsView(@photo) ).comments_html()
    $("#pic_detail .comments").listview('refresh')
  
  render_new_comment_field: =>
    $(".new_comment .user").html current_user_fullname()
    
  jump_to_comments: =>
    target = $("#pic_detail .comments").offset.top()
    $.mobile.silentScroll(target)
  
  save_new_comment: =>
    value = @constructor.new_comment_value()
    return if value is ""
    LoaderSpinner.show_spinner()
    @photo.comments.unshift(body: value, user: current_user())
    @constructor.reset_entry_field()        
    @render_comments()
    @on_update() if @on_update
    LoaderSpinner.hide_spinner()
    NetworkHandler.instance({
      url: Config.base_url() + "/photos/comment/#{@photo.id}",
      data: {body: value},
      type: "POST",
      dataType: "json",
      success: (response) =>
        # LoaderSpinner.hide_spinner()
        @photo.comments = response
        @photo.save()
        # @render()
        @on_update() if @on_update
      error: -> $.mobile.changePage("#network_error")
    }).run()
         
# ===========================
# = THE VIEWS =
# ===========================   

# Just a simple view that shows how many likes there were
class window.LikesSummaryView 

  constructor: (photo) ->
    @photo = photo
    
  html: ->
   $("<div class='icon_with_text likes_stats'>
        <div class='npb_extended_icon npb-icon-heart'></div>
        <div class='text de-emphasize2'>(#{@photo.likes})</div>
      </div>")
 

# Just a simple view that shows how many comments there were
class window.CommentsSummaryView

  constructor: (photo) ->
    @photo = photo

  html: ->
    $("<div class='icon_with_text comments_stats'>
         <div class='npb_extended_icon npb-icon-chat'></div>
         <div class='text de-emphasize2'>(#{@photo.comments.length})</div>
       </div>")

# A view on all the comments, either in gallery view or in the photo view
class window.CommentsView
  @INSTANCE: null
  
  constructor: (photo, for_gallery=false) ->
    CommentsView.INSTANCE = @
    @photo = photo
    @for_gallery = for_gallery
  
  comment_html: (comment) =>
    $("<li class='npb-wrap' data-icon='false'>
         <p class='user'>#{comment.user.first_name} #{comment.user.last_name}</p>
         <p class='body'>#{comment.body}</p>
       </li>")
  
  comment_html_for_gallery: (comment) =>
    $("<div class='comment'>
         <p class='user'>#{comment.user.first_name} #{comment.user.last_name}</p>
         <p class='body'>#{comment.body}</p>
       </div>")
    
  comments_html: (n=-1) => @photo.comments.first(n).map (c) => if @for_gallery then @comment_html_for_gallery(c) else @comment_html(c)
  

# Class that paints the status view for photos
class window.CommentsLikesStatsView

  constructor: (photo,jq_element) ->
    @photo = photo
    @jq_element = jq_element

  render: =>
    if @jq_element
      @jq_element.html @html()

  comments_html: =>
    (new CommentsSummaryView(@photo)).html()
    
  likes_html: =>
    (new LikesSummaryView(@photo)).html()
    
  # TEMPORARY - this doesn't really belong here but I want a visual indicator that shows
  # that the photo still has to upload
  photo_status_html: =>
    display_char = 
    if @photo.is_new_record()
      switch @photo.status
        when Photo.STATUS.UPLOAD_PENDING then 'o'
        when Photo.STATUS.UPLOADED then '!'
        when Photo.STATUS.UPLOADING 
          if @photo.upload_percent then "#{@photo.upload_percent}%" else '...'
        when Photo.STATUS.UPLOAD_FAILED then 'x'

    else if @photo.has_local_image() 
      "."
    else null
    if display_char 
      $("<span class='photo_status de-emphasize2'>#{display_char}</span>")
    else
      null

  # This adds a little icon to show if the thumb has been downloaded or not
  thumb_status_html: =>
    if @photo.has_local_thumb()
      $("<span class='photo_status de-emphasize2'>:</span>")
    else
      ""
      
  html: -> 
    cl = $("<div class='comments_likes_stats'></div>")
    cl.html [@photo_status_html(), @thumb_status_html(), " &nbsp; ", @comments_html(), @likes_html()]
    cl
    

$(document).ready ->
  $(window).on "resize", ZoomView.size_pic
  $("#pic_zoom").on "pageshow", ZoomView.size_pic
  $("#pic_zoom .pic").on "click", ZoomView.back
  
class window.ZoomView
  @size_pic: => 
    $("#pic_zoom .pic").css("width", "#{2*$(window).innerWidth}px")
  
  @back: =>
    $.mobile.changePage("#pic_detail")
