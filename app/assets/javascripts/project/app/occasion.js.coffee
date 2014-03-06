# Occasion class defines occasion objects which are placed and retrieved from localstorage by the CurrentOccasion class 
# To add a new occasion just call new Occasion
# You will probably want to save it to the server as such:
# occasion = new Occasion name: "foo"
# occasion.save_to_server()
# This will automatically add it locally as well
class window.Occasion extends ActiveModel


  @STATUS: {
    CHANGED: "changed",
    UNCHANGED: "unchanged",
    NEW_CONTENT: "new content"
    ERROR: "error"
  }
  # #############
  # Server
  # #############

  # This is used by active_model to load all the instances from the server
  @list_update_uri = "/occasions/occasions_json"

  # how long to wait before refreshing the list.  Note, no timer associated with this - it's just that if a refresh is called 
  # and the list has been loaded some time before this, we ignroe the refresh call, in seconds
  @list_cache_time: 3600

  # Time stamp of when this was list was last updated
  @last_updated: null

  @plural_name: ->
    "albums"

  # Find an occasion by name
  @find_by_name: (name) ->
    return null unless name
    for instance in @instances
      return instance if instance.name.toLowerCase() == name.toLowerCase()
    return null

  # Refresh the occasions list - not that this 
  @refresh: (callback,force) ->
    if !@last_updated or force or ((new Date()) - @last_updated > @list_cache_time*1000) 
      @load_from_server(callback)
    else
      Logger.log("Not refreshing occasions because it was refreshed #{(((new Date()) - @last_updated)/1000).toFixed(0)} seconds ago")

  # If we are loading from the server, make sure we order the occasions, and then
  # call the original callback
  @load_from_server: (callback) ->
    Logger.log("Calling occasions load_from_server")
    super (success,response) => @loaded_occasions(success,response); callback(success,response) if callback

  # Called when the occasions have been loaded from the server
  # WARNING: we don't want to overwrite an instance where there may be a photo waiting for upload
  # If some occasions were deleted on the server, we want to remove them locally
  @loaded_occasions: (success, response) =>
    return unless success && response instanceof Array 

    @last_updated = now()
    current_ids = @ids()
    new_ids = response.ids()
    unless current_ids.join() == new_ids.join()
      Logger.log("Occasion: reorganizing to match server ids = #{JSON.stringify(current_ids)}, response ids = #{JSON.stringify(new_ids)}")
      instances = []
      for id in response.ids()
        instances.push(@find(id))
      @instances = instances
      @queue_save()

  # #############
  # Class Utility Methods
  # #############

  @full_list_for_auto_complete: => @instances && ( @instances.map (o) -> id: o.id, str: o.name.capitalize_words() ).sort (a,b) -> a.str > b.str
  @names: => @instances.map (o) -> o.name

  # ###########
  # OVERRIDE INSTANCE METHODS
  # ###########

  # Returns a list of attribute name value pairs, including the participants which is itself a list of name-value pairs
  # Because we sae the photos elsewhere, we only return the photo id's here
  attributes: -> 
    attributes = super 
    # No need to save the heavy photo objects
    attributes.photo_ids = @photos.ids()
    delete attributes["photos"]
    attributes

  # ###########
  # INSTANCE METHODS
  # ###########

  # Don't include the photos here because we deal with it separately...  We go into each photo and determine what 
  # has changed and how to deal with it.
  @attribute_names: ["id","name","city","thumbnail","thumb_id","start_time","participants","last_updated_on","version"]
  @new_content_attributes: ["photos"]

  # constructor: (obj={}) ->
  #   @update(obj)
  #   @normalize_name()

  initialize: (params={}) ->
    @participants ||= []
    @photos ||= []
    @photo_ids ||= []

  constructor: (params={}) ->
    super
    @setup_photos(params)
    @

  # If update is called with the object itself, just return
  update: (params={}) ->
    return @ if @ is params
    if super
      @setup_photos(params)
    @

  # Overwrite the default urid to provide a bit more info
  urid: ->
    "Occasion[#{@id}] #{@name}"

  # Setup the photos for this occasion. Note that this method could be called with the object itself, not just a hash of params
  # This method tries to figure out if new photos were added on the server, and if old photos that haven't been uploaded yet are
  # on the client.  It tries to merge them in based upon the time when the photos were taken
  setup_photos: (params={}) ->
    # We should be provided with either photos or photo ids (we save the photo ids, but when we get the occasion from server, it comes with 
    #full photo descriptions.  If we get the photos (coming back from the server), then we should add any new ones, but we should also keep track
    # of any that are local so that we don't lose the local images that are waiting for upload

    return if params is @

    # Logger.log("Setting up #{params.photos} photos for occasion "+@id)
    if params.photos 
      local_photo_info = []
      for photo,i in @photos
        if photo.is_new_record() 
          local_photo_info.push({index:i, photo: photo})
          Logger.log("Local photo at index "+i)

      # This is the old number of photos that the server thought it had
      old_photos_count = @photos.length - local_photo_info.length
      new_photos_count = params.photos.length - old_photos_count
      if local_photo_info.length == 0 && new_photos_count == 0 
        Logger.log("Occasion #{@id} photos unchanged")
      else
        Logger.log("Occasion #{@id} had #{old_photos_count} server photos, update shows #{new_photos_count} new photos, and #{local_photo_info.length} photos are still uploading")
      @photos = []
      for photo in params.photos
        @photos.push Photo.add(photo)

      # Now insert the local photos back in the array at approximately the right positions.  The assumption is that any new 
      # photos are added to the head, that is, they are more recent, so we need to insert our old photos into the same positions
      # but offset by the number of new photos
      new_photos_count = params.photos.length - old_photos_count
      @new_content = true if new_photos_count > 0
      for photo_info,i in local_photo_info
        index = new_photos_count + photo_info.index
        Logger.log("Inserting old photo id #{photo_info.photo.id} at position "+index)
        @photos[index...index] = photo_info.photo

    # The assumption is photo ids are coming from local saves so we don't need to make any arrangements
    # wrt existing.  If there are photos that aren't in the local store, we need to update the occasions!
    else if params.photo_ids
      corrupted = false
      @photos = []
      for id in params.photo_ids
        if p = Photo.find(id)
          @photos.push(p)
        else
          Logger.error("Updating an occasion with photo #{id} that we could not find")
          # If this is a photo that is on the server, then reload the whole shabang.  If it's a local photo
          # then reloading from the server won't help us... It's sadly lost!
          # UGH - a bit ugly that we are embedding knowledge of negative ID's at this level of the codebase....
          # TODO - refactor to put in the testing of id in a separate method
          unless Photo.id_is_for_new_record(id)
            corrupted = true
            break
      if corrupted
        @constructor.queue_reload(10)
   
    if @thumb_id && p = Photo.find(@thumb_id)
      p.prepare_thumb_for_display()
    else
      @thumb_id = if @photos[0] then @photos[0].id else null

    this

  remove_photo: (arg) ->
    if typeof arg == "number" 
      id = arg
    else if arg instanceof Photo
      id = arg.id

    photos = (photo for photo in @photos when photo.id != id)

    if photos.length != @photos.length
      if photo = Photo.find(id) then photo.remove()

      Logger.log("Remove photo #{id} from occasion #{@id}")
      @photos = photos
      @queue_save()

    photos.length


  thumb: ->
    Photo.find(@thumb_id) if @thumb_id 
      
  # Capitalize the name
  normalize_name: =>
    @name = @name.trim().capitalize_words() if @name?
  
  normalize: => @normalize_name()
  
  # To fix old ones that were not normalized when created. 
  display_name: => @normalize_name()
  
  # Create a new photo for this occasion and add ito the 
  # photos
  new_photo: (params) ->
    p = Photo.add($.extend(params,{occasion_id: @id}))
    @photos.unshift(p)
    @save()
    p.save_to_server()

  # save the occasions to with server
  # For some reason, when I was sending device_state() I was getting into an infinite recursion and running out of stack space
  # Not sure why, though because nothing in device_state() calls save_to_server().  
  save_to_server: (params={})->
    Logger.log("Trying to save the occasion #{@name} to the server")
    Logger.log(params)
    NetworkHandler.instance({
      url: Config.base_url() +  "/occasions/create"
      dataType: "json"
      type: "POST"
      retry_count: 0
      data: {occasion: {name: @name, id: if @id < 0 then null else @id }, app_info: app_info(), location: current_location()}
      success: (response) => 
        @update(response)
        @save()
        Logger.log "Successfully saved occasion #{@name} to server "
        if params.success?
          params.success()
      error: (jqXHR, textStatus, errorThrown) =>
        Logger.log "Failed to save occasion #{@name} to server "
        Logger.log("params = "+ JSON.stringify(params.error))
        if params.error?
          Logger.log("Calling provided error handler" + params.error.toString())
          params.error()
    }).run()

  # update this occasion from the server
  load_from_server: (callback)->
    time = new Date()
    NetworkHandler.instance({
      url: Config.base_url() + "/occasions/get/" + @id
      dataType: "json"
      type: "get"
      retry_count: 0
      message: "Refreshing Album"
      success: (response) =>
        if Object.keys(response).length > 0
          @update(response)
          @last_updated_on = time
          status = if @new_content then Occasion.STATUS.NEW_CONTENT else if @changed then Occasion.STATUS.CHANGED else Occasion.STATUS.UNCHANGED
          callback(status,@) if typeof callback is "function"
          Logger.log("Updated occasion #{@name} from server. Status: #{status}")
          @save() if @changed
        else
          Logger.log("Occasion #{@name} was not updated from server") 
          callback(Occasion.STATUS.UNCHANGED,@) if typeof callback is "function"
      error: (jqXHR) =>
          callback(Occasion.STATUS.ERROR,@) if typeof callback is "function"
    }).run()

  update_if_needed: (params={}) ->
    @load_from_server($.extend(params,{data: {time: @last_upated_on}}))

  prepare_for_display: ->
    for p in @photos
      p.prepare_thumb_for_display()

  # Prepare the occasion for removal by deleting its photos
  prepare_for_removal: ->
    Logger.log("Preparing occasion #{@id} for removal")
    Photo.remove(@photos.ids())


  ################
  # LOCAL ALBUM INTERACTIONS
  ################

  album_name: ->
    AlbumController.occasion_album_name(@)

  save_to_album: ->
    
  # Create an album for 
  create_album: ->
    AlbumController.create_album(@album_name, (results) -> alert("Created album #{results.album_name}"))


  # #############
  # INSTANCE UTILITY METHODS
  # #############
  add_participants: (participants) => @add_participant p for p in participants
  add_participant: (participant) => @participants.push participant unless @has_participant(participant)
  has_participant: (participant) => 
    for p in @participants 
      return true if p.first_name is participant.first_name and p.last_name is participant.last_name
    false
      
    
  num_participants: => @participants.length
  other_participants: => @participants.filter (p) -> p.id != current_user().id
  has_participants: => @other_participants().length > 0
  other_participants_names: => @other_participants().map (p) -> {first_name: p.first_name, last_name: p.last_name}
  other_participants_first_and_li: => @participants_names().map( (n) -> first_and_last_initial(n) ).sort()
  participants_names: => @participants.map (p) -> {first_name: p.first_name, last_name: p.last_name}
  participants_full_names: => @participants_names().map( (n) -> full_name(n) ).sort()
  photos_by_user: (user) => @photos.filter (p) -> p.creator.id == user.id
  num_photos: => @photos.length
  num_photos_by_user: (user) => @photos_by_user(user).length
  num_photos_by_current_user: => if current_user() then @num_photos_by_user(current_user()) else 0
  


    
