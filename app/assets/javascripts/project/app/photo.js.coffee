class window.Photo extends ActiveModel

  ##############
  # CLASS VARIABLES (+ others defined in ActiveModel)
  ##############

  # Maximum number of simultaneous thumbnail download threads
  @MAX_THUMB_DOWNLOAD_THREADS = 4

  @photos_directory = null

  @download_queue = []
  @thumb_download_queue = []

  @attribute_names: ["id","occasion_id","url","thumb_url","time","creator","longitude","latitude","caption","likes","comments","width", "height", "aspect_ratio", "tmp_file_uri","likers","orientation","local_image_url","local_thumb_url"]
  @new_content_attributes: ["likes","comments","likers"]

  @instances = []
  @file_entry_queue = []
  @file_entry_timer = null

  # this is just a test variable 
  @no_uploads = false

  @STATUS: {  
              UPLOADED: "uploaded", 
              UPLOADING: "uploading", 
              UPLOAD_FAILED: "upload failed", 
              UPLOAD_PENDING: "upload pending",
              DUPLICATE: "duplicate",
              DOWNLOADING: "downloading",
              DOWNLOADED: "downloaded",
              DOWNLOAD_ERROR: "download error"
            }

  ##############
  # CLASS METHODS
  ##############

  # Make sure the file system is ready to store the photos and their thumbnails
  # We create an photos directory on the file system, and inside it we create files
  # named <id>.jpg and <id>_thumb.jpg for the thumbnails
  # We also subscribe to the network_ok event so we can clear any pending photos 
  # when the app detects that we have a good network connection
  @init: =>
    if Config.is_running_on_device()
      if @photos_directory 
        Logger.log("No need to init photo directory")
      else
        Logger.log("Getting entry for photo directory")
        window.requestFileSystem(LocalFileSystem.PERSISTENT, 0,
          # WARNING - if you change the photos directory name, search because it's referenced elsewhere
          (fs) => fs.root.getDirectory(Config.app_photo_album, {create: true}, 
            (dir) => 
              Logger.log("Photos directory = "+dir.fullPath)
              #  to use the @ sign I need to make both bindings =>
              @photos_directory = dir
            () => alert("Error creating photos directory") ), 
          (event) -> alert("Error getting file system: " + event.target.error.code))

      NetworkHandler.register_observer(@network_ok)


  # Queue the for reloading the file entries for this photo
  @queue_file_entry_load: (photo) =>
    Logger.log("Adding photo #{photo.id} for later file entry loading")
    @file_entry_queue.push(photo)
    unless @file_entry_timer
      @file_entry_timer = window.setTimeout(@flush_file_entry_queue,1000)


  @flush_file_entry_queue: =>
    if @photos_directory
      Logger.log("Flushing #{@file_entry_queue.length} photos waiting for file entries")
      window.clearTimeout(@file_entry_timer)  if @file_entry_timer
      @file_entry_timer = null
      for photo in @file_entry_queue
        photo.update_file_entries()
      @file_entry_queue=[]
    else
      @file_entry_timer = window.setTimeout(@flush_file_entry_queue,1000)
     

  # Called when the network is OK
  @network_ok: =>
    @flush_uploads()

  @queue_for_download: (p) ->
    for instance in @download_queue 
      if instance.id == p.id
        Logger.log("Photo #{p.id} already queued for download")
        return false
    Logger.log("Queueing photo #{p.id} for download")
    @download_queue.push(p)
    return true

  @queue_thumb_for_download: (p) ->
    for instance in @thumb_download_queue 
      if instance.id == p.id
        Logger.log("Thumbnail for  #{p.id} already queued for download")
        return false
    Logger.log("Queueing thumbnail #{p.id} for download")
    @thumb_download_queue.push(p)
    if @thumb_download_queue.length < @MAX_THUMB_DOWNLOAD_THREADS
      p.download_thumb()

      # p.set_thumb_download_timer((@thumb_download_queue.length + 1) * 1000)
    return true

  # Find the next item in the queue that is not downloading and start the download
  @download_next_thumb_in_queue: =>
    for instance in @thumb_download_queue 
      continue if instance.thumb_downloading 
      instance.download_thumb()
      break

  @process_thumb_download_queue: =>
    downloading = (instance for instance in @instances when instance.thumb_downloading)
    if downloading.length < @MAX_THUMB_DOWNLOAD_THREADS && downloading.length < @thumb_download_queue.length
      @download_next_thumb_in_queue()

  # Download all the queued images - when each is done, call the indicated callback
  @flush_download_queue: (callback = (p) -> Logger.log("Photo #{p.id} image downloaded")) ->
    for p in @thumb_download_queue
      p.download_thumb()
    for p in @download_queue
      p.download()

  @remove_from_download_queue: (photo_to_remove) =>
    if photo_to_remove && @download_queue.remove(photo_to_remove)
      Logger.log("Removed photo #{photo_to_remove.id} from download queue")

  @remove_thumb_from_download_queue: (photo_to_remove) =>
    if photo_to_remove && @thumb_download_queue.remove(photo_to_remove)
      @download_next_thumb_in_queue()
      Logger.log("Removed thumbnail for photo #{photo_to_remove.id} from download queue")

  # Prepare the indicated photos by downloading the images if required
  # INPUT: list of ids
  # OUTPUT: list of ids that will be downloaded
  # ASSUMPTION: all ids already exist in our local photos storage, and their file entries have been loaded
  @prepare_for_display: (ids) ->
    for id in ids 
      if p = Photo.find(id)
        @queue_thumb_for_download(p) unless p.has_local_thumb()
        @queue_for_download(p) unless p.has_local_image()
      else
        Logger.error("Photo unable to find id #{id} for prepare")
    @flush_download_queue()


  # If the app is in the background, then comes back in foreground, there may be some photos that are 
  # awaiting upload, so we have to call them
  @flush_uploads: ->
    waiting = @awaiting_upload()
    if waiting.length > 0 
      Logger.log("Flushing #{waiting.length} uploads")
    for p in waiting
      p.save_to_server()

  # Let's actually remove all the files (images) associated with the photos
  # Includes both the large image and the thumbnail
  @remove_all_files: ->
    @cleanup()
    for p in @instances
      p.remove_image_file()
      p.remove_thumb_file() 
    true

  # Clears out the files and the objects
  @clear_all: ->
    @remove_all_files()
    super

  # Remove a photo (or list of ids) from the instances
  # If we remove a photo, we also have to remove it in the corresponding occasions
  @remove: (arg) ->
    removed = super
    for instance in removed
      if occasion = instance.occasion()
        occasion.remove_photo(instance)
    removed

  # remove all files that are not associated
  # with a current photo ID.  This is useful
  # when we switch users in testing, so get photos
  # associated with old occasions on our system
  @cleanup: ->
    if @photos_directory
      @photos_directory.createReader().readEntries(
        ((entries) => 
          ids = @ids()
          # Logger.log("Cleanup: we have #{ids.length} ids")
          for file_entry in entries
            # Logger.log("Checking file #{file_entry.name} for removal")
            if id = parseInt(file_entry.name.replace(/\D/g,''))
              unless id in ids
                Logger.log("Removing file #{file_entry.name} ")
                file_entry.remove()
        )
      )

  # Calculates the disk usage in bytes and sets up the value in disk_usage_bytes.  Because it's asynchronous
  # it can't return anything
  @du: ->
    if @photos_directory
      @photos_directory.createReader().readEntries(
        ((entries) => 
          @disk_usage_bytes = 0
          @calculating_disk_usage = 0
          Logger.log("Photo directory has #{entries.length} entries")
          for file_entry in entries
            @calculating_disk_usage++
            file_entry.file((file) => @disk_usage_bytes += file.size; @calculating_disk_usage--)
        )
      )
      # Temporary hack for testing
      window.setTimeout( (=> Logger.log("Usage = #{@disk_usage_bytes} with #{@calculating_disk_usage} still pending")), 1000)
      null

  ################
  #  VARIOUS FINDERS
  ################
  @for_occasion: (id) ->
    instance for instance in @instances when instance.occasion_id == id 

  @with_comments: ->
    instance for instance in @instances when instance.comments.length > 0

  @liked: ->
    instance for instance in @instances when instance.likes > 0

  @with_local_images: ->
    instance for instance in @instances when instance.file_entry

  @with_local_thumbs: ->
    instance for instance in @instances when instance.thumb_file_entry
    
  @awaiting_upload: ->
    instance for instance in @instances when instance.is_new_record()

  @with_thumb_downloading: ->
    instance for instance in @instances when instance.thumb_downloading

  ###############
  #  UTILITY METHODS
  ###############
  
  @clean_caption: (caption) -> caption.trim().escape_html().strip_vertical_space().truncate(60)
  
  @as_file_url: (path) ->
    if path.indexOf("file://") == 0
      path
    else
      "file://#{path}"

  # True if the file is in the native camera photo gallery
  @is_phone_gallery_file: (file_entry) ->
    file_entry and file_entry.fullPath.indexOf(@photos_directory.fullPath) is -1

  ##############
  # OVER-RIDDEN ABSTRACT INSTANCE METHODS
  ##############


  # Do any initializations that you don't want to be null
  initialize: ->
    @comments ||= []
    @time ||= new Date().toUTCString()
    @likers ||= []

    # Reset the updating flag indicating that the record is updating in an asynchronous operation
    @file_status = @FILE_STATUS.INACTIVE
    @thumb_file_status = @FILE_STATUS.INACTIVE

  # We don't want to update the file entries for all photos right at the beginning because it's slow
  constructor: (params={})->
    super
    # @update_file_entries(params) 

  update: (params={}) ->
    super
    @update_file_entries(params)


  # This is called to upgrade the object, presumably after it is loaded from local
  # storage
  # Upgrade the object if necessary
  upgrade_if_needed: ->
    if @likes > 0 && @likes != @likers.length
      Logger.log("Upgrading photo #{@id}")
      @load_from_server()

  ##############
  # PHOTO-ONLY INSTANCE METHODS
  ##############

  FILE_STATUS: {
                  INACTIVE: null,
                  PROCESSING: 'processing',
                  PROCESSED: 'processed',
                  UNPROCESSABLE: 'unprocessable'
                }

  update_file_entries: (params={}) ->
    return null if not Config.is_running_on_device() || @is_file_processing()

    # If given a file entry, then we just use it
    if params.file_entry 
      @file_entry = params.file_entry
      @local_image_url = @constructor.as_file_url(@file_entry.fullPath)
      # @local_image_url = @file_entry.toURL();

    if params.thumb_file_entry
      @thumb_file_entry = params.thumb_file_entry 
      @local_thumb_url = @constructor.as_file_url(@thumb_file_entry.fullPath)
      # @local_thumb_url = @thumb_file_entry.toURL();

    # The photos directory may not be ready yet, in which case 
    # we need to queue the photos that we couldn't get the file entries for
    # and try again later
    if ( !@file_entry or !@thumb_file_entry ) && !@constructor.photos_directory
      @constructor.queue_file_entry_load(@)
      return

    # If we don't have the file entries for either the thumbnail or image, then get them
    @get_thumb_file_entry() unless @thumb_file_entry
    @get_image_file_entry() unless @file_entry
        
      # If we are provided with a uri instead of a path, then we 
      # convert it to a file path
      # else if @tmp_file_uri 
      #   Logger.log("Updating tmp file uri for "+@id)
      #   @file_status = @FILE_STATUS.PROCESSING
      #   Filer.uri_to_file(@tmp_file_uri, @update_image_file_entry)

  # GARF: The photo is not ready if we're still gathering it's fileEntry 
  # information - at that point we can't really query if much about it, so we don't know if it has a local
  # image file or not, for example
  is_file_processing: ->
    @file_status == @FILE_STATUS.PROCESSING

  is_file_processed: ->
    @file_status == @FILE_STATUS.PROCESSED

  is_file_processable: ->
    @file_status == @FILE_STATUS.INACTIVE


  is_thumb_processing: ->
    @thumb_file_status == @FILE_STATUS.PROCESSING

  is_thumb_ready: ->
    @thumb_file_status == @FILE_STATUS.PROCESSED

  is_thumb_processable: ->
    @thumb_file_status == @FILE_STATUS.INACTIVE

  occasion: ->
    Occasion.find(@occasion_id)

  # return the display url to use for this photo. If it's local, it will use the current url, else if
  # we have the tmp file URI we will 
  display_url: ->
    if @has_local_image() 
      @local_image_url
      # @constructor.as_file_url(@local_image_file_path())
    else 
      if Config.is_running_on_device()
        @download() if @url 
        return @tmp_file_uri or if @url then  LpUrl.full_url(@url) else ""
      else 
        return ( @url and LpUrl.full_url(@url) ) or @tmp_file_uri or ""

  thumb_display_url: ->
    if @has_local_thumb() 
      @local_thumb_url
      # @constructor.as_file_url(@local_thumb_file_path())  
    else
      if Config.is_running_on_device() 
        @queue_thumb_for_download() if @thumb_url and Config.is_running_on_device()
        return @tmp_file_uri or if @thumb_url then LpUrl.full_url(@thumb_url) else ""
      else
        return ( @thumb_url and LpUrl.full_url(@thumb_url) ) or @tmp_file_uri or ""
    
  add_comment: (comment) -> 
    @comments.unshift(comment)
    @
  
  # In the case where you snap a photo with the camera in the app you get null for the aspect ratio.
  # Gallery_handler puts Nan in for height and fortunately since the photo loads quickly enough
  # it is able to calculate the frame heights based on the height of the loaded photo. This is hokey. But setting to 
  # a default value like .75 breaks this. Ideally Snapping a photo should return an aspect ratio and orientation.
  aspect: -> @aspect_ratio # or .75
 
  update_caption: (caption) -> @caption = Photo.clean_caption caption
    
  #########################
  # File System
  #########################

  # Return the file path
  local_image_file_path: (relative=false) ->
    if relative 
     "#{@id}.jpg" 
    else if @constructor.photos_directory
      # @constructor.photos_directory.toURL() + "/#{@id}.jpg" 
      @constructor.photos_directory.fullPath + "/#{@id}.jpg" 
    else null

  # This would be the thumbnail path in our system.  If we don't have an ID yet, just use the 
  # actual image file path
  local_thumb_file_path: (relative=false) ->
    if relative 
      "#{@id}_thumb.jpg" 
    else if  @constructor.photos_directory
      # @constructor.photos_directory.toURL() + "/#{@id}_thumb.jpg" 
      @constructor.photos_directory.fullPath + "/#{@id}_thumb.jpg" 
    else
      null

  # get the file Entry associated with this photo
  # private 
  get_image_file_entry: () ->
    file_path = @local_image_file_path(true)
    return unless @is_file_processable() and file_path and @constructor.photos_directory and file_path.indexOf("://") is -1

    # Logger.log("Updating file entry for "+@id)
    @file_status = @FILE_STATUS.PROCESSING
    @constructor.photos_directory.getFile(file_path, { create: false }, @update_image_file_entry, => @file_status = @FILE_STATUS.PROCESSED ; @image_missing_callback())

  # update the photo with the file entry after we have converted it from a URI 
  update_image_file_entry: (fileEntry) =>
    @remove_from_download_queue()
    @file_entry = fileEntry
    @local_image_url = @constructor.as_file_url(fileEntry.fullPath)    
    # @local_image_url = fileEntry.toURL()    
    @file_status = @FILE_STATUS.PROCESSED
    @queue_save()
    Logger.log("Photo #{@id} updated image file entry - local url "+@local_image_url)

  clear_image_file_entry: =>
    Logger.log("Photo.clear_file_entry id=#{@id}")
    @file_entry = null
    @local_image_url = null

  # The the file entry for the thumbnail associated with the photo
  get_thumb_file_entry: () ->
    return unless @is_thumb_processable() and @constructor.photos_directory and (thumb_file_path = @local_thumb_file_path(true)) and thumb_file_path.indexOf("://") is -1
    # Logger.log("Updating thumbnail file entry for "+@id)
    @thumb_file_status = @FILE_STATUS.PROCESSING
    @constructor.photos_directory.getFile(thumb_file_path, { create: false }, @update_thumb_file_entry,  => @thumb_file_status = @FILE_STATUS.PROCESSED; @image_missing_callback())

  # update the photo with the file entry after we have converted it from a URI 
  update_thumb_file_entry: (fileEntry) =>
    @remove_thumb_from_download_queue();
    @thumb_file_entry = fileEntry
    @local_thumb_url = @constructor.as_file_url(fileEntry.fullPath)    
    # @local_thumb_url = fileEntry.toURL()
    @thumb_file_status = @FILE_STATUS.PROCESSED
    @queue_save()
    Logger.log("Photo #{@id} updated thumb file entry - local url "+@local_thumb_url)

  clear_thumb_file_entry: =>
    Logger.log("Photo.clear_thumb_file_entry id=#{@id}")
    @thumb_file_entry = null
    @local_thumb_url = null
  
  clear_tmp_file_uri: =>
    Logger.log("Photo.clear_tmp_file_uri id=#{@id}")
    @tmp_file_uri = null
  
  # Save the image locally after getting confirmation that it saved in the server
  # This shouldn't fail hopefully. If it does, we'll eventually
  # make it silent
  # GARF - this will fail because we're trying to bridge file systems
  # Instead I have to create a file reader and a file writer... never midn it all - we'll just re-download the image
  local_save_image: (params={}) ->
    @tmp_file_uri.moveTo(@constructor.photos_directory,
      "#{@id}.jpg",
      (entry) =>  Logger.log("Successfully moved photo "+@id+" to "+entry.fullPath),
      (error) => alert("Error moving photo "+@id+" to "+entry.fullPath)
      )

  # GARF: This will no longer work cleanly because we likely won't have the file entries for this photo
  remove_image_file: (force=false) ->
    if @local_image_url and not @file_entry
      Logger.warn("Requested to remove image file for #{@id} but no file entry")
    if @file_entry and (not Photo.is_phone_gallery_file(@file_entry) or force)
      # Don't remove the file if it's the original temporary file      
      @file_entry.remove((=> @clear_image_file_entry(); Logger.log("Removed image file for photo #{@id} ")), (=> Logger.error("Removing image file for photo "+@id)))

  remove_thumb_file: () ->
    if @local_thumb_url and not @thumb_file_entry
      Logger.warn("Requested to remove thumb file for #{@id} but no file entry")
    if @thumb_file_entry
      @thumb_file_entry.remove((=> @clear_thumb_file_entry(); Logger.log("Removed thumbnail file for photo #{@id} ")), (=> Logger.error("Removing thumbnail file for photo "+@id)))
    else
      # Logger.log("WARNING: unable to remove thumbnail file for photo #{@id} due to no file_entry ")

  # ASYNCHRONOUS METHODS
  # This method is called in a callback when we determine that the local image
  # file exists in persistent or temporary storage!
  image_exists_callback: (entry) =>
    if entry.fullPath.match(/photos\/\d+.jpg/)
      @local_image_status = "persistent"
    else
      @local_image_status = "temporary"

    if @exists_callback
      @exists_callback(@)

  # This method is called in a callback when we determine that the local image
  # file does NOT exist in persistent or temporary storage!
  image_missing_callback: (error) =>
    @local_image_status = "missing"
    if @missing_callback
      @missing_callback(@)

  # Check if there is a local image associated with this photo.  Call the appropriate callback method
  # This is a pain because of the stupid asynchronous stuff
  # GARF - photos_directory may not be initialized when this is called
  # NOT USED!!!
  # check_if_local_image_exists: (exists_callback = (-> Logger.log("Photo #{@id} has local image file")), missing_callback = (-> Logger.log("Photo #{@id} does not have local image file"))) ->
  #   @exists_callback  = exists_callback
  #   @missing_callback = missing_callback
  #   @constructor.photos_directory.getFile(@file_path(true), { create: false }, @image_exists_callback, @image_missing_callback);

  # SYNCHRONOUS METHOD - MUCH EASIER - use this instead.
  # This is a different way of determining if we have a local image synchronously
  # NOTE: This does not check for the URL that may be associated with image and is from gallery
  # or camera
  # TODO: Should be called has_downloaded_image()
  has_local_image: ->
    if @local_image_url
      true
    else if not @is_file_processing()
      @file_entry?
    else
      Logger.log("Checking to see if Photo #{@id} has a local image but it is not ready (#{@file_status})")
      false

  has_device_image: ->
    @has_local_image() or @tmp_file_uri?

  # NOTE: This does not check for the URL that may be associated with image and is from gallery
  # or camera.  
  # TODO: Should be called has_downloaded_thumb()
  has_local_thumb: ->
    if @local_thumb_url
      true
    else if not @is_thumb_processing()
      @thumb_file_entry?
    else
      Logger.log("Checking to see if Photo #{@id} has a local thumbnail but it is not ready (#{@thumb_file_status})")
      false

  # Prepare this photo for display, which means, first update the file entries to see if they are ready
  # 
  prepare_for_display: ->
    if @has_local_image()
      return
    else if @is_file_processed() 
      @download() unless @has_local_image() || @is_new_record()
    else  
      @update_file_entries()
     

  # Prepare thumbnail for display
  prepare_thumb_for_display: ->
    if @has_local_thumb()
      return
    else if @is_file_processed()
      @download_thumb() unless @has_local_thumb() || @is_new_record()
    else  
      @update_file_entries()

  # the photo is about to be removed, so clean up anyting that is required
  prepare_for_removal: ->
    @remove_image_file()
    @remove_thumb_file()
    
  file_size: ->
    if @file_entry
      @file_entry.file((file) => console.log("photo #{@id} image size = #{file.size}"))
    else
      console.log("file for photo #{@id} is not ready yet")

  thumb_file_size: ->
    if @thumb_file_entry
      @thumb_file_entry.file((file) => console.log("photo #{@id} image size = #{file.size}"))
    else
      console.log("file for photo #{@id} is not ready yet")
  
  url_type: (url) ->
    type = {}
    switch
      when url.match(RegExp @local_image_url)
        type.local_remote = "l"
        type.size = "hr"
      when url.match(RegExp @local_thumb_url)
        type.local_remote = "l"
        type.size = "thm"
      when url.match(RegExp @tmp_file_uri)
        type.local_remote = "l"
        type.size = "tmp"
      when url.match(RegExp @url)
        type.local_remote = "r"
        type.size = "hr"
      when url.match(RegExp @thumb_url)
        type.local_remote = "r"
        type.size = "thm"
    return type
  
  clear_local_url: (url) ->
    switch
      when url.match(RegExp @local_image_url)
        @clear_image_file_entry()
      when url.match(RegExp @local_thumb_url)
        @clear_thumb_file_entry()
      when url.match(RegExp @tmp_file_uri)
        @clear_tmp_file_uri()
        
  fix_thumb_display_url_if_broken: (callback_if_broken) =>
    return unless @has_local_thumb()
    @broken_thumb_callback = callback_if_broken
    # resolve localFileSystemURL was introduced with cordova File 1.0.0 we are using cordova File 0.2.5
    # resolveLocalFileSystemURL(@local_thumb_url, @local_thumb_ok, @local_thumb_is_broken)
    path = @constructor.photos_directory.name + "/" + @local_thumb_file_path(relative=true)
    @constructor.photos_directory and @constructor.photos_directory.filesystem.root.getFile(path, {create:false}, @local_thumb_ok, @local_thumb_is_broken)
    
  local_thumb_ok: => 
    # Logger.log("Photo.fix_thumb_display_url_if_broken: local thumb ok for photo[#{@id}]")
    
  local_thumb_is_broken: => 
    Logger.log("Photo.fix_thumb_display_url_if_broken: Found broken local thumb for photo[#{@id}] - cleared local entry.")
    @clear_thumb_file_entry()
    @broken_thumb_callback and @broken_thumb_callback()

  ################
  # LOCAL ALBUM INTERACTIONS
  ################

  # returns true if the photo is already saved to the local device album
  saved_to_album: ->
    !!@album_url 

  # Returns true if the album image exists for the local image
  album_image_exists: ->
    @album_image_validated

  # Check to see if the album image exists for this photo
  check_album_image: ->
    Logger.log("Photo: checking if album image exists for #{@id}")
    if @album_url
      AlbumController.check_image_exists(@id, @album_url, 
        (results) => 
          @album_image_validated = true 
          Logger.log("Photo: Image for #{@id} " + if results.exists then "exists" else "missing")
      )

  save_image_to_album: ->
    Logger.log("Photo: saving image for #{@id} to album")
    AlbumController.save_photo(@,
      (results) -> 
        @album_url = results.image_url
        @album_image_validated = true
      )

    
  ################
  # SERVER INTERACTIONS
  ################

  # Queue the image for download 
  # NOTE - don't think this is used any more...
  queue_for_download: =>
    @constructor.queue_for_download(@)

  remove_from_download_queue: => 
    @constructor.remove_from_download_queue(@)
  
  queued_for_download: =>
    @ in @constructor.download_queue

  downloading: =>
    @status is Photo.STATUS.DOWNLOADING
      

  # Download the photo image file from the server and save it in permanent storage
  # This only makes sense if we actually have a url
  download: (callback = (p) -> Logger.log("Successfully downloaded image for photo #{p.id} to " + p.file_entry.fullPath)) =>
    return null unless NetworkHandler.network_ok()
    if Config.is_running_on_device() 
      if @url? && not @downloading() && not @is_file_processing()
        if file_path = @local_image_file_path()
          url = encodeURI(LpUrl.full_url(@url))
          ft = new FileTransfer();
          Logger.log("Photo: Downloading photo #{@id} from "+@url)
          @download_started = now()
          @set_status Photo.STATUS.DOWNLOADING
          ft.download(
            url,
            file_path,
            (entry) => 
              @update_image_file_entry(entry) 
              @set_status Photo.STATUS.DOWNLOADED;
              Logger.log("Photo: Finished downloading photo #{@id} in #{ms_since(@download_started)} ms")
              callback(@)
            (error) => @set_status(Photo.STATUS.DOWNLOAD_ERROR); Logger.log("Error #{error.code} downloading image for photo #{@id} : "+error.target)
            )
        else
         Logger.log("WARN: couldn't download image for photo [#{@id}] because file path was null")
      else
        Logger.log("WARN: request to download image for photo [#{@id}] but url was missing or it was already processing or downloading")
    else
      # Logger.log("Not on device, but presume to have successfully downloaded image for photo #{@id}")
      # p.fileEntry = new FileEntry
      # callback(@)

  set_thumb_download_timer: (value) =>
    @thumb_download_timer = window.setTimeout(@download_thumb, value)
        
  queue_thumb_for_download: =>
    @constructor.queue_thumb_for_download(@)

  thumb_queued_for_download: =>
    @ in @constructor.thumb_download_queue

  remove_thumb_from_download_queue: => 
    @constructor.remove_thumb_from_download_queue(@)
    window.clearTimeout(@thumb_download_timer) if @thumb_download_timer
    @thumb_download_timer = null
    
  # Download the photo image file from the server and save it in permanent storage
  # This only makes sense if we actually have a url
  download_thumb: (callback = (p) -> Logger.log("Successfully downloaded thumbnail for photo #{p.id} to " + p.thumb_file_entry.fullPath)) =>
    if Config.is_running_on_device() 
      return null unless NetworkHandler.network_ok()

      if @thumb_url? && not @thumb_downloading && not @is_thumb_processing()
        if thumb_file_path = @local_thumb_file_path()
          url = encodeURI(LpUrl.full_url(@thumb_url))
          ft = new FileTransfer();
          Logger.log("Downloading photo thumbnail #{@id} to "+thumb_file_path)
          @thumb_downloading = true
          @thumb_download_started = now()
          ft.download(
            url,
            thumb_file_path,
            (entry) => 
              @thumb_downloading = false
              @update_thumb_file_entry(entry)
              Logger.log("Photo: Finished downloading thumbnail #{@id} in #{ms_since(@thumb_download_started)} ms")
              callback(@)
            (error) => 
              @thumb_downloading = false; 
              Logger.log("Error #{error.code} downloading thumbnail for photo #{@id} : "+error.target)
              @remove_thumb_from_download_queue();
            )
        else
          Logger.log("WARN: couldn't download thumbnail for photo [#{@id}] because thumb file path was null")

      else
        Logger.log("WARN: request to download thumbnail for photo [#{@id}] but url was missing or it was already processing or downloading")
    else
      # Logger.log("Not on device, but presume to have successfully downloaded thumbnail for photo #{@id}")
      # p.thumb_file_entry = new FileEntry
      # callback(@)

  @test: (file) ->
    NetworkHandler.instance({
      url: Config.base_url() + "/photos/test",
      file: file, 
      mime_type: "image/jpeg", 
      dataType: "json",  
      retry_count: 1,
      success: (r) => 
        Logger.log "Success"
      error: =>
        Logger.log "Error" 
    }).run()
    
  uploadable: ->
    !@status || @status == Photo.STATUS.UPLOAD_FAILED

  # Save this photo to the server
  # This should only be called for unsaved photos
  save_to_server: (callback=null) ->
    return if @constructor.no_uploads

    if NetworkHandler.processing_upload(@tmp_file_uri) 
      Logger.log("Request to save photo #{@id} to server but was already in progress")
      return

    @callback = callback
    @set_status Photo.STATUS.UPLOAD_PENDING
    @upload_percent = 0
    NetworkHandler.instance({
      url: Config.base_url() + "/photos/create",
      file: @tmp_file_uri, 
      mime_type: "image/jpeg", 
      dataType: "json",  
      retry_count: 50,
      other_params: {
        tmp_file_uri: @tmp_file_uri, #used by server photo_cont.create when simulating picking from gallery on the browser.
        time: @time, 
        occasion_id: @occasion_id, 
        latitude: @latitude, 
        longitude: @longitude,
        caption: @caption,
        app_info: JSON.stringify(app_info())
        },
      success: (r) => 
        if r.id 
          # If this was a duplicate, it may be that we already have it in our occasion.... If so, just remove
          # this.  However, there are cases when the photo is uploaded, but file transfer plugin fails before
          # we get the response.  In this case, we have the photo registered in the occasion on the server side
          # but not here.  So when we send it again, it comes back and we don't have it in the occasion, and we 
          # register it
          if r.duplicate && (r.id in @occasion().photos.ids())
            # Quietly remove myself - the photo was a duplicate
            Logger.log("Received a duplicate photo id #{r.id}")
            @constructor.remove(@id)
            @set_status Photo.STATUS.DUPLICATE
            return            
          @update(r)
          @save()
          @occasion().save()
          @set_status Photo.STATUS.UPLOADED
          @callback(@) if @callback
      error: (fail_status) =>
        Logger.log "Photo #{@id} save_to_server failed with fail status #{fail_status}" 
        if fail_status == NetworkHandler.FAIL_STATUS.WILL_RETRY
          @set_status Photo.STATUS.UPLOAD_PENDING
        else if fail_status == NetworkHandler.FAIL_STATUS.HOPELESS
          # This should really only happen if the photo is really really old, taken with the camera, and the temporary file
          # has been removed...
          # We remove it silently because it shouldn't happen that often...
          Logger.log("Photo #{@id} removed from occasion #{@occasion_id} because saving it is hopeless")
          @set_status Photo.STATUS.UPLOAD_FAILED
          @remove()
        else if fail_status == NetworkHandler.FAIL_STATUS.FAILED
          @set_status Photo.STATUS.UPLOAD_FAILED
        @status_changed()
        @callback(@) if @callback
      progress: (percent) =>
        if percent != @upload_percent 
          @upload_percent = percent
          # We sometimes seem to get progress events fast and furiou, so only process them if they
          # are more than 500 ms apart
          if !@last_progress_update_time  or (new Date().getTime() - @last_progress_update_time > 500) or percent == 100
            Logger.log("Photo #{@id} percent uploaded = #{percent}")
            @set_status Photo.STATUS.UPLOADING
            @last_progress_update_time = new Date().getTime()
            @callback(@) if @callback

    }).run()
  
  set_status: (status) =>
    @status = status
    @status_changed()
  
  status_changed: => $(document).trigger("photo_status_change", [@])
    
  load_from_server: (callback) ->
    NetworkHandler.instance({
      url: Config.base_url() + "/photos/get/#{@id}",
      dataType: "json"
      message: "Refreshing photo"
      success: (r) =>
        @update(r)
        if @changed
          @save() 
          @occasion().save()
        callback(@) if callback
    }).run()

  # UTILITY METHODS
  liked_by_user: (user) ->
    if @likers && (@likers instanceof Array )
      @likers.ids().indexOf(user.id) isnt -1

  thumb_status: ->
    if @thumb_downloading then "downloading" else if @thumb_queued_for_download() then "queued for download" else if @has_local_thumb() then "local" else "remote"

  image_status: ->
    if @downloading() then "downloading" else if @queued_for_download() then "queued for download" else if @has_local_image() then "local" else "remote"

  pps: ->
    super + "\n" + 
    [
      "thumb status: " + @thumb_status(),
      "image status: " + @image_status(),
      "thumb url:" + @thumb_display_url(),
      "image url: " + @display_url()
    ].join("\n") 

