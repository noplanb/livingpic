# This is the base object for an object that is syncable
# We have 3 instances we need to sync up and care about
#  - The object(s) that are in memory
#  - The object(s) that are stored locally
#  - The object(s) that are on the server
# The objects in memory are either updated from local storage or from the server
# Whenever the objects in memory are updated, they must flush the other persistent storage
#   If updated from UI, for example, we need to update both the server and local storage
#   If updated from the server, we need to update local storage
# In this model we only save the entire object locally in a hash-like model, that is, a non-relational model,
# but it would be nice to obscure that from the client
# So we prefix the update with either local or server, depending on whether we're acting locally or the server
#   e.g. we have update (update in-memory object), server_update, and local_update
#        local_save and server_save
#        load and server_load (aka refresh)
#  
#  We don't bother with delete b/c for now the client can't delete anything 
class window.ActiveModel

  # Track when we last updated from the server, and the flush_queue
  @last_updated = null
  @flush_queue = []

  # list_update_uri is the URL to call to update the list of objects
  # NOTE: no need to include the base_url.  Just the uri
  @list_update_uri: null
  @object_update_uri : null
  @object_create_uri: null

  # List of instances.  We may keep these in memory
  # Arrays also need to be defined in the child classes
  # NOT so for scalars
  @instances = []

  # Flag indicating if the in-memory representation is different from what we have saved
  # on the system.  

  @dirty = false

  # Parameters having to do with object comparisons and determining of the local phone copy of the object
  # has changed or not
  @changed = false
  @new_content = false
  @attribute_names=["id"]

  ###########################
  #    Class methods
  ###########################

  # Important use single-arrow - because this method references the name object in the extended class
  # It's a very lame implementation of Rails' table_name - very weak pluralization
  @storage_name: ->
    @name.toLowerCase() + "s"

  # Return the plural name for the object, for example, "Photo" becaomes "photos"
  @plural_name: ->
    @storage_name()
    
  # prepends an object with the indicated params to the list
  # We expect params to be a parameters hash
  @add: (params,options={}) ->
    # Logger.debug("Adding #{@name} id "+params.id)
    if params.id and (o = @find(params.id))
      o.update(params)
      if o.changed
        Logger.debug("#{@name}[#{o.id}] has changed")
        @dirty = true 

    else
      o = if params instanceof @ then params else eval("new #{@name}(params)")

      if options.append then @instances.push(o) else @instances.unshift(o)
      unless options.no_save_needed
        # Logger.log("Adding new #{@name} [#{o.id}]")
        @dirty = true 
    
    # Let's queue a save if there were any dirty records
    @queue_save() if @dirty 
    o

  # Pushes a new instance with the indicated params
  # We check to make sure an occasion with that ID doesn't already exist.  If there is 
  @append: (params,options={}) ->
    @add(params, $.extend(options,{append:true}))

  # Tries to update the instance pointed to by the params.id with the parameters
  # If not found, nothing is done
  @update: (params) ->
    if instance =  @find(params.id)
      instance.update(params)
    instance

  # Remove the items with the indicated ids from the list
  # if the argument is a function, we delete everything that matches the function, 
  # else if it's an object we assume it's the object itself, and finally, if none of 
  # these we assume it's an array
  # Returns the list of objects that were removed
  @remove: (arg) ->
    instances_to_remove = []
    if typeof arg == "function"
      instances_to_remove = (instance for instance in @instances when arg(instance))
    else if arg instanceof @
      Logger.log("Removing #{@name} id #{arg.id}")
      instances_to_remove = (instance for instance in @instances when instance is arg)
    else if typeof arg == "number"
      Logger.log("Removing #{@name} id #{arg}")
      instances_to_remove = (instance for instance in @instances when instance.id is arg)
    else
      instances_to_remove = (instance for instance in @instances when instance.id in arg)

    if instances_to_remove.length > 0 
      for instance in instances_to_remove
        instance.prepare_for_removal()
      @instances = (instance for instance in @instances when instance not in instances_to_remove)
      @local_save()

    instances_to_remove

  # Sets the object instances based upon a simple array of attribute hashes.
  # This should only be called when loading - anyone else should call append() and add()
  @set_instances: (params_array,options={}) ->
    if params_array
      # Logger.log("Setting instances for "+params_array.length + " instances")
      if options.overwrite
        Logger.log("Resetting existing #{@name} instances with #{params_array.length} new objects")
        @instances = [] 
      good_instances = []
      for params in params_array
        o = @append(params,{no_save_needed: true})
        o.upgrade_if_needed() if options.local_load
        good_instances.push(o)

      # If an old instance was removed on the server, then delete it locally as well
      if @instances.length != good_instances.length
        for instance in @instances
          if good_instances.indexOf(instance) == -1
            instance.remove()
    else
      Logger.log("Can't set #{@name} instances with null input")

  @clear_all: ->
    @instances = []
    @local_save()

  # A tmp id is generated for all objects.  It's negative to differentiate it from 
  # actual IDs
  @new_tmp_id: ->
    id = appState.get("am_tmp_id") || 0
    id--
    appState.set("am_tmp_id",id)
    id

  # True if the id is for a new record.  Put here to encapsulate all logic for tmp ids
  # in one place
  @id_is_for_new_record: (id) ->
    id < 0
  
  @normalize_to_id: (object) -> if typeof object is "object" then parseInt(object.id) else parseInt(object)
  @normalize_to_object: (id) -> if typeof id is "object" then id else @find(id)   
  
  # #############
  # Local Storage
  # #############
  # Load all the instances from local storage
  # unless the file is dirty in which case we don't load because we 
  # don't want to overwrite any changes
  @local_load: (options={})->
    if @dirty
      Logger.log("Not Loading #{@storage_name()} from local storage because memory cache is dirty")
    else
      local_instances = appState.get(@storage_name()) || []
      Logger.log("Loading #{local_instances.length} #{@storage_name()} from local storage ")
      @set_instances(local_instances, $.extend(options,{overwrite: true,local_load:true}))

  # Just a safety method to load the instances if they are empty
  @local_load_if_necessary: (options={})->
    if @instances.length == 0 then @local_load(options)

  # Save all the instances to local storage.  Note that this has to be a single-arrow definition
  # else we end up with "activeModels" as the storage name.
  @local_save: ->
    start = now()
    appState.set(@storage_name(), @instances.map (o) -> o.attributes() )
    Logger.log("Saved #{@instances.length} #{@storage_name()} to local storage in #{ms_since(start)} ms")
    @dirty = false
    for instance in @instances
      instance.changed = false
      instance.new_content = false
    window.clearTimeout(@save_timer) if @save_timer
    @save_timer = null

  # Save the models to disk if any were dirty, ie. a parameter changed in them
  @local_save_if_needed: ->
    @local_save() if @dirty

  # We don't save a single location we save them all together
  @save: (instance) ->
    # Logger.log("Saving #{@name}s with instance "+JSON.stringify(instance))
    @add(instance) if instance
    @local_save()

  # Queue up a timer to save the in-memory records because they have changed
  # We do this in a timer because we ma be updating multiple records at once
  # and we would like there to be enough time to have done them before
  # we save them
  @queue_save: (timer_value) ->
    unless @save_timer
      timer_value ||= 1000
      Logger.log("Setting up timer for #{timer_value}ms to save #{@storage_name()}")
      f = => @local_save()
      @save_timer = window.setTimeout(f,timer_value)

  # Reload the objects after some timer value - 
  # NOTE: may not be used
  @queue_reload: (timer_value) ->
    unless @reload_timer
      timer_value ||= 1000
      Logger.log("Setting up timer  for #{timer_value}ms to reload #{@storage_name()}")
      f = => @load_from_server()
      @reload_timer = window.setTimeout(f,timer_value)

 # #############
  # Server
  # #############

  # Sync with the server
  # NOT DONE OR TESTED
  @server_save: ->
    for instance in @server_unsaved() 
      instance.save_to_server()

  # Loading from the server.  Will call the callback whether successful or not
  # with a flag that indicates if it was successful
  # Set retry_count to 0 so we don't retry this many times
  @load_from_server: (callback=null) ->
    Logger.log("Refreshing the #{@name} list at #{Config.full_url(@list_update_uri)} for User #{current_user().id}")
    NetworkHandler.instance({
      url: Config.full_url(@list_update_uri)
      retry_count: 0,
      message: "Refreshing #{@plural_name()}"
      error: (retrying,r) => 
        # Let's call the callback even in this case if we have cached instances
        if callback && !@empty()
          Logger.log("#{@name}: Calling server_load callback in error case")
          callback(false,r)     
      success: (r) => 
        if r instanceof Array
          Logger.log "Loaded #{r.length} #{@name}s from server"
          @last_server_load = new Date().getTime()
          # GARF - we want to overwrite the instances if there is nothing
          # local - else we don't want to overwrite them
          @set_instances(r,{overwrite:false})
          @local_save()
          window.clearTimeout(@reload_timer) if @reload_timer
          @reload_timer = null
          if typeof callback is "function"
            # Logger.log("#{@name}: Calling server_load callback" + callback.toString())
            callback(true,r) 
        else
          Logger.error("load_from_server for #{@name}s received object r is not an array: "+JSON.stringify(r))
      }).run()
  
  # Refresh from the server - basically a synonym for load_from_server
  @refresh: (callback=null) ->
    # We load this locally and then load from the server otherwise
    # @local_load()
    @load_from_server(callback)

  # Only loads from server if it is needed, that is, there are no instances
  @refresh_if_needed: (callback=null) ->
    if @instances.length == 0
      @local_load()
      @refresh(callback)

 
 # #############
  # Finder methods
  # #############
  @all: ->
    @local_load_if_necessary()
    @instances
    
  # NOTE: we are basing last based upon ID, not a parameter
  @last: ->
    for instance in @instances
      last = instance if not last? or last.id < instance.id
    last

  @first: ->
    for instance in @instances
      first = instance if not first? or first.id > instance.id
    first
    
  @most_recent: ->
    @instances[0]

  # Instances that are not yet saved to the server
  @server_unsaved: ->
    instance for instance in @instances when instance.is_new_record()

  @find: (ids) ->
    if is_array(ids)
      return ids.map (id) => @find(parseInt id)
    else
      id = parseInt(ids)
      return null unless id
      for instance in @instances
        return instance if instance.id == id or instance.tmp_id == id
      return null

  # Find an instance by an attribute
  # NOTE: It only returns the first instance it finds, not all of them
  @find_by_attribute: (attribute,value) ->
    return null unless attribute
    for instance in @instances
      return instance if instance[attribute] == value
    return null

  @count: ->
    @instances.length
    
  # #############
  # Utility Methods
  # #############
  @empty: ->
    @instances.length == 0

  @ids: -> @.instances.map  (o) -> o.id
  @ids_as_strings: -> @ids().map (id) -> id.toString()
  @attr: (attr) -> @instances.map  (o) -> o[attr]

  # Simply querying to see if we already have the objects with the indicated ID
  # Input: array of id's
  # Output: array of id's that we have
  @have: (id_list) ->
    current_ids = instance.id for instance in @instances
    current_ids.intersect(id_list)
      

  # Indicate if we already have all the ids provided in the list
  @have_all: (id_list) ->
    if @instances.length == id_list.length
      @have(id_list).length == id_list.length
    else
      false

  # Returning the ids that we can't find in-memory (presumably also in local storage)
  @missing: (id_list) ->
    current_ids = instance.id for instance in @instances
    current_ids.diff(id_list)

  # ############################################
  # ABSTRACT INSTANCE METHODS TO OVERRIDE
  # ############################################

  # The user readable id
  urid: ->
    "#{@constructor.name}[#{@id}]"

  # Normalize whatever needs to be normalized before saving
  # e.g. remove trailing or leading spaces
  #   remove dashes in a phone number, etc.
  normalize: ->

  # Should be implemented by the child class to initialize any other 
  # parameters with the object
  initialize: ->

  # This returns the list of attributes for the instance, much like activeModel.  Essentially,
  # it converts the object into a hash
  # this is the equivalent of the activeModel attributes
  # It is required for saving the object
  attributes: ->
    attributes = {}
    for attr in @constructor.attribute_names
      attributes[attr] = @[attr]
    attributes
      

  upgrade_if_needed: ->

  # ######################
  # INSTANCE METHODS
  # ######################

  constructor: (params={}) ->
    for attr in @constructor.attribute_names
      @[attr] = params[attr]
    @initialize()

    # Generate a temporary ID unless we have a real ID passed in
    unless @id
      @tmp_id ||= @constructor.new_tmp_id()
      @id = @tmp_id
    @normalize()

  # Only update the parameters that are provided.  If an attribute changed, mark that it changed
  # WARNING - only supports simple types (i.e. numbers & strings & Arrays) - does not support objects/hashes
  # FOR arrays, it only checks the length, does not do an element by element check
  # Child classes should override if they want a better implementation
  update: (params={}) ->
    if @id < 0 
      Logger.log("Updating #{@constructor.name} with tmp id #{@id} with id #{params.id}: "+JSON.stringify(params))

    provided_keys = (key for key of params)
    # Check if the version has changed, but only if we have a version attribute
    if params["version"] && @version && @version is params["version"]
      Logger.debug("#{@urid()} has unchanged version #{@version}")
      @changed = false
      @new_content = false
    else
      Logger.debug("Checking to see if #{@urid()} has changed")
      for attr in @constructor.attribute_names
        if provided_keys.indexOf(attr) >= 0
          # Logger.log("Updating parameter "+attr)
          if @[attr] instanceof Array
            if params[attr] && @[attr].length != params[attr].length
              Logger.debug("#{@constructor.name}[#{@id}] #{attr} changed from length #{@[attr].length} to #{params[attr].length}")
              @changed = true
              @new_content = true if attr in @constructor.new_content_attributes
          else if (typeof @[attr] == "string" || typeof @[attr] == "number") && @[attr] != params[attr]
            Logger.debug("#{@constructor.name}[#{@id}] #{attr} changed from #{@[attr]} to #{params[attr]}")
            @changed = true
            @new_content = true if attr in @constructor.new_content_attributes

          @[attr] = params[attr]
    @changed


  # This is a save to local storage
  # The normalize_name call here may be redundant if we're always creating the instances via a @constructor
  save: ->
    @normalize()
    Logger.log("Saving #{@constructor.name} id "+@id)
    @constructor.save(@)

  queue_save: ->
    @normalize()
    @constructor.queue_save()

  # Determine if the instance is a new record. For now we assume it's local
  # if the ID does not have a positive value
  is_new_record: ->
    !@id? || @id < 0

  # Save a single object to the server
  # For some reason, when I was sending device_state() I was getting into an infinite recursion and running out of stack space
  # Not sure why, though because nothing in device_state() calls save_to_server().  
  save_to_server: (params={})->
    Logger.log("Trying to save the #{@constructor.name} #{@name} to the server")
    Logger.log(params)
    NetworkHandler.instance({
      url: Config.base_uri() +  @constructor.object_create_uri
      dataType: "json"
      type: "POST"
      retry_count: 0
      data: @create_data()
      success: (response) => 
        @update(response)
        @save()
        Logger.log "Successfully saved  #{@constructor.name} #{@name} to server "
        if params.success?
          params.success()
      error: (jqXHR, textStatus, errorThrown) =>
        Logger.log "Failed to save #{@constructor.name} #{@name} to server "
        Logger.log("params = "+ JSON.stringify(params.error))
        if params.error?
          Logger.log("Calling provided error handler" + params.error.toString())
          params.error()
    }).run()

  # Remove this object
  remove: ->
    @constructor.remove(@)


  # Override if there is anything to be done to prepare the object for removal
  prepare_for_removal: ->
    Logger.log("Please override this if you actually want to do anything prior to object removal")

  # Pretty print 
  pps: ->
    output = []
    output.push "id: " + @id
    for attribute in keys(@attributes()).sort()
      continue if attribute is "id"
      if attribute instanceof Array
        value = JSON.stringify(@[attribute])
      else if attribute instanceof Object
        value = "Object"
      else 
        value = @[attribute]
      output.push attribute + ": " + value

    output.join("\n")

