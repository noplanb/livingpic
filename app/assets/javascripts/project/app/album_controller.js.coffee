# Controller class for interfacing to the native device albums
class window.AlbumController

  @urls: []

  # Let's keep track of the instances here
  @instances: []

  @init: ->
    @plugin = window.plugins.AlbumInterface unless Config.is_running_in_browser()

  # Return a new AlbumController instance
  @instance: ->
    unless found = @free()[0]
      found = new AlbumController()
      @instances.push found 
    found

  @free: ->
    instance for instance in @instances when instance.is_free()

  # This is the primary method of interest: Load the album images from the camera roll.  
  # Indicate:
  # The callback function (none)
  # the number to return (all)
  # and the offset (0)
  # TODO - this should be called as an instance method...
  @load_album: (callback, count, offset) =>
    @load_album_callback = callback
    @plugin.getPhotosWithThumbs(@load_album_done,@album_error,count,offset)

  # Called when the album is loaded
  # The results as returned to callback have the following fields:
  # id: an image ID 
  # image_url: the url for the image
  # thumb_url: the url for the thumbnail
  @load_album_done: (results) =>
    @urls = results
    Logger.log("AlbumController load done #{@urls.length} images from the camera album")
    photos = []
    # TODO - ios doesn't give us a thumbnail URL, so let's put the image URL as the thumb url and see how it goes
    for image_info,i in @urls
      # Let's use a negative ID here to make sure we distinguish this from the ID's that correspond
      # to the photos coming from server
      photos.push new AlbumPhoto id: -i, image_info: image_info
    Logger.log("calling load_album_callback with #{photos.length} photos")
    @load_album_callback(photos) if @load_album_callback

  # Creates an album with the indicated name
  @create_album: (name,callback)=>
    @instance().create_album(name,callback)

  @check_album_exists: (album_name,callback) =>
    @plugin.albumExists(album_name, @check_album_exists_done,@album_error)

  @check_album_exists_done: (results) =>
    Logger.log("Album #{results.album_name} found = #{results.exists}")

  # Saves the image pointed to by the filepath to the named albm
  @save_image_to_album: (id,image_file_path, album_name,callback) =>
    @plugin.saveImage(id, image_file_path,album_name, @save_image_to_album_done,@album_error)

  @save_image_to_album_done: (results) =>
    photo = Photo.find(results.id)
    photo.album_url = results.image_url
    Logger.log("Saved image #{results.image_id} with url #{results.image_url} to album #{results.album_name}!")

  @check_image_exists: (image_id, image_url) =>
    @plugin.imageExists(image_id, image_url, ( (results) -> Logger.log("image #{results.image_id} exist = #{results.exists}") ),@album_error)

  @check_image_exists_done: (results) =>

  # Main method called when there is an error
  @album_error: (message) ->
    alert("Sadly, the operation failed with message: #{message}")

  # This saves the occasion and all its images.  For each image, we check to see if the image already exists
  # as best we can
  @save_occasion: (occasion,success_callback) =>
    occasion = if occasion instanceof Occasion then occasion else Occasion.find(occasion) 
    @instance().create_album(@occasion_album_name(occasion), 
      (results) => 
        Logger.log("Album for occasion #{occasion.id} saved.  Now saving images")
        for photo in occasion.photos
          unless photo.album_image_exists()
            photo.save_image_to_album()

      )

  # Derive the name of the album for a given occasion
  @occasion_album_name: (occasion) ->
    "[LP] " + occasion.name

  # Saves the indicated photo to the album associated with its occasion
  @save_photo: (photo,success_callback) ->
    Logger.log("Saving photo #{photo.id}")
    @instance().save_image(photo.id, photo.display_url(),@occasion_album_name(photo.occasion()),success_callback)

#############################
# Instance Properties and Methods
#############################

  # IMPLEMENTATION NOTE
  # I have implemented the instance methods w/o any notion of higher-level objects like
  # Photo or occasion.  The reason is that I would like to be able to publish this to the
  # plugin library w/o having these depencencies.  It's not super-clean but I'm keeping the
  # class methods as the linkage to the higher-level objects

  # success callback for this instance
  @on_success: null
  @status:  null

  STATUS: {  
            FREE: "free", 
            PENDING: "pending", 
          }


  # Creates a new instance
  constructor: (params) ->
    @id = @constructor.instances.length + 1
    @status = @STATUS.FREE
    Logger.log ("Created new AlbumController instance with id "+@id)

  create_album: (name, success_callback) =>
    @mark_busy()
    @on_success = success_callback
    @constructor.plugin.createAlbum(name, 
      (results) => 
        Logger.log("AlbumController: album #{results.album_name} " + if results.new then "created" else "existed")
        @mark_free()
        @on_success(name) if @on_success
      @album_error)

  # Save the image to the indicated album name
  save_image: (id, image_url, album_name, success_callback) =>
    @mark_busy()
    @on_success = success_callback
    @constructor.plugin.saveImage(id, image_url, album_name, 
      (results) =>
        Logger.log("AlbumController: successfully saved image #{results.id} to #{results.album_name}")
        @mark_free()
        @on_success(results) if @on_success
      @album_error)

  # Generic method called when there is an error
  album_error: (message) =>
    @mark_free()
    @constructor.album_error(message)

  check_image_exists: (image_id, image_url, on_success) ->
    @constructor.plugin.imageExists(image_id, image_url, 
      ( (results) -> 
        Logger.log("image #{results.image_id} exist = #{results.exists}") 
        on_success(results) if on_success
      ),
      @album_error)

  # Some utility functions
  mark_free: -> @status = @STATUS.FREE
  mark_busy: -> @status = @STATUS.PENDING

  is_free: -> @status == @STATUS.FREE
  is_pending: -> @status == @STATUS.PENDING
  
# Test STUFF 

  @test_save_album: (album) =>

  @test_save_image: (id,album)=>
    id ||= Photo.with_local_images().ids()[0]
    album ||= "foo"
    @save_image_to_album(id,Photo.find(id).display_url(),album)

  @test_image_exists: (id) =>
    id ||= Photo.with_local_images().ids()[0]
    photo = Photo.find(id)
    @check_image_exists(id, photo.album_url)

  @render_photos: ->
    if !@urls or @urls.length == 0
      Logger.warn("AlbumController did not receive any URLS")
      return

    s = ""
    for url in @urls
      thumbnail_data = url.thumbnail_data
      # s += "<div class='album_photo'> <img src='data:image/jpeg;base64,#{thumbnail_data}' width='100'></div>\n"
      # s += "<div class='album_photo'> <img src='#{url.image_url}' width='154'></div>\n"
      s += "<div class='album_photo'><img class='zoom_photo' src='#{url.image_url}' width='154'></div>"

    s += '<div class="buttonRow"> <a href="" data-role="button" data-inline="true" data-theme="a" data-mini="true" data-rel="back">Cancel</a>&nbsp;&nbsp;<a href="" data-role="button" data-inline="true" data-theme="a" data-mini="true" class="upload">Upload</a> </div>'
    pics = $("#native_album .pics")
    pics.html(s)
    $("#native_album .album_photo img").on("click", 
      (e) -> 
        $(e.target).toggleClass("selected");
    )
    $("#native_album a.upload").on("click", @selection_done)
    $("#native_album .zoom_photo").css {
      top:  "10px"
      left: "10px"
      width: "154px"
      display: "block"
    }
    Pager.change_page("native_album")

  @zl: "#zoom_block"

  @asset: true
  @zoom = false
  @render_one: ->
    url = @urls[0]
    if @asset
      s = "<img class='zoom_photo' src='#{url.image_url}' width='154'>"
    else
      s = "<img class='zoom_photo' src='#{Photo.instances[0].display_url()}' width='154'>"
    $(@zl).html(s)
    @ze = $(@zl).find(".zoom_photo")
    # @ze.on("load",@after_load) if @ze
    @after_load()
    # Pager.change_page("native_album")

  @after_load: ->
    @ze.css {
      top: "100px"
      left: "10px"
      width: "154px"
      display: "block"
    }
    @ze.off("load",@after_load)
    @zoomit() if @zoom

  @zoomit: ->
    @zp = new Zoomer(@ze,{zp_el: @ze})

  @selection_done: ->
    image_urls = []
    image_urls =  (img.src for img in $("#native_album .pics .album_photo img.selected"))
    Logger.log("image url count = "+image_urls.length)
    # TODO - only add the photo if it doesn't already exist
    # BUG - doesn't this add the URL for the thumbnail rather than the actual image???
    for url in image_urls
      current_occasion().new_photo(tmp_file_uri: url, caption: "", latitude: current_location().latitude, longitude: current_location().longitude, creator: current_user(), comments:[], likes:0)
    GalleryController.show_current()

  @loopback: ->
    @startTime = (new Date).getTime();
    @plugin.loopback(=> Logger.log("Loopback succeeded in "+(new Date).getTime() - @startTime))
  

# ==============
# = AlbumPhoto =
# ==============
class window.AlbumPhoto
  
  constructor: (params={}) ->
    @id = params.id
    @image_info = params.image_info || throw "AlbumPhoto: expecting params.image_info"
    image_info = params.image_info || {}
    @image_url = image_info.image_url
    @thumb_url = image_info.thumb_url
    @thumb_data = image_info.thumbnail_data
    @width = image_info.width
    @height = image_info.height
    # SANI: I think thumbnails are square in IOS, so I set aspect ratio to 1.0 so that 
#    @aspect_ratio = 1.0   
    
  display_url: => @image_url
  
  thumb_display_url: => if @thumb_data then 'data:image/png;base64,' + @thumb_data else @thumb_url or @image_url
    

