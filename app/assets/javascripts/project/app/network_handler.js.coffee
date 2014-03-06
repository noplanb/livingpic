# For handling the network connectivity.   Using this rather than host_handler b/c the latter has a ton of code for page management
# General idea behind the networkHandler:
#  - centralize the logic around checking for network connectivity, and logging errors when there is a connectivity problem
#  - retries if they are needed
# Works with both ajax calls (use send method) and file uploads (use .upload)
class window.NetworkHandler 

  # Timeouts to catch hung network handlers
  @FILE_TIMEOUT = 120 * 1000
  @AJAX_TIMEOUT = 60 * 1000

  # These are the various failed statuses
  @FAIL_STATUS: {
    WILL_RETRY: "will retry",
    FAILED: "failed",
    HOPELESS: "hopeless"
  }

  # CLASS VARIABLES
  # Support multiple instances
  @instances: []

  # Track the timing of the connection errors, and ping errors, which are unique to pinging the system
  # and have the start time when ping failed and the end time.  May get rid of these but for initial
  # tests want to see if we are experiencing network or ping errors.  Ideally should not have any ping errors
  # Server errors should track the url and the time when at which it was attempted.  Again, useful for initial
  # implementations to check out the status
  @network_errors: []
  @ping_errors: []
  @server_errors: []
  @hung_errors: []
  @observers: []

  # Test parameters to fool the system
  # Set to true to simulate a bad network
  @test_bad_connection: false
 
  # Set to true to simulate a bad server (affects Config.base_url)
  @test_bad_server: false

  ##############
  # Class Methods
  ##############

  # Load up the instances that were saved previously.  Only load if there isn't already 
  # something in here to avoid adding instances that already exist
  @init: =>
    if @instances.length == 0 && params_array = appState.get("network_params")
      Logger.log("NetworkHandler init with #{params_array.length} instances")
      for params in params_array 
        @instance(params).status = "pending"

  @instance: (params) ->  
    if  found = @free()[0] 
      found.setup(params)
    else
      found = new NetworkHandler($.extend(params,{id:@instances.length}))
      @instances.push found
      Logger.log("Creating new NetworkHandler instance.  Instances count =  " + @instances.length)
    found.status = "allocated"
    return found
  
  # Save all the instances.  We do this on pause.
  @save_instances: (params) =>
    appState.set("network_params", @in_progress().map (i) -> i.params)

  @clear_saved_instances: =>
    appState.set("network_params",[])

  @register_observer: (observer_method) ->
    return if observer_method in @observers
    @observers.push(observer_method)

  # Notify observers when there is connectivity
  @notify_observers: ->
    for o in @observers
      o()

  # Track the time when we encountered the error.  More important for server errors than network errors,
  # and probably overkill, but worth having for a small release.  We track how long the network or server was out
  # Each marks the beginning and end
  @mark_error: (type) ->
    counter = if type == "ping" then @ping_errors else @network_errors
    time = (new Date).getTime()
    if counter.length < 2 
      counter.push(time) 
    else
      counter[1] = time
     
  @add_server_error: (url) ->
    if @server_errors.length < 20
      @server_errors.push([url,(new Date).getTime()])

  @add_hung_error: (url) ->
    if @hung_errors.length < 20
      @hung_errors.push([url,(new Date).getTime()])


  # Notify the server of errors that we encountered via the eventhandler to be of consistent format
  # GARF - this is a bit hokey because it could fail, in which case we have reset the errors 
  @notify_server_of_errors: =>
    Logger.log("Notifying server of errors") if @network_errors.length + @ping_errors.length + @server_errors.length > 0
    EventHandler.log_to_server({type: "network_error", value: @network_errors}) if @network_errors.length > 0
    @network_errors = []
    EventHandler.log_to_server({type: "ping_error", value: @ping_errors}) if @ping_errors.length > 0
    @ping_errors = []
    EventHandler.log_to_server({type: "server_error", value: JSON.stringify(@server_errors)}) if @server_errors.length > 0
    @server_errors = []
    EventHandler.log_to_server({type: "hung_error", value: JSON.stringify(@hung_errors)}) if @hung_errors.length > 0
    @hung_errors = []

  @check_server: =>
    Logger.log("Checking server connectivity")
    @instance({
      url: LpUrl.full_url("/ping")
      async: true
      retry_count: 0
      success: (data) =>
        @server_ok()
      error: (jqXHR, textStatus, errorThrown) =>
        # connectivity error to server - probably don't do anything now but keep stats
        @set_timer()
        @mark_error("ping")
        Logger.error("Error connecting to server: status(#{textStatus}), Error(#{errorThrown})")
    }).run()
  
  # Callback when the server is OK
  @server_ok: =>
    Logger.log("connectivity OK")
    @clear_timer()
    @notify_server_of_errors()
    @notify_observers()
    @flush_queue()

  # Called to check the network
  @check_network: =>
    ok = @network_ok() 
    if not ok then @mark_error("network")
    ok

  # Returns the network status
  @network_ok: =>
    return false if @test_bad_connection
    navigator.connection.type != "none" 

  @network_status: =>
    navigator.connection.type

  # Check the connectivity via the device network interface
  # This gives us additional information about whether the device
  # is connected via wifi or data network
  @check_connectivity: =>
    if @check_network() 
      @check_server() 
    else
      @set_timer()


  @free: =>
    instance for instance in @instances when instance.is_free()
  
  @active: => @instances.filter (i) -> not i.is_free()
  
  @is_active: => not @active().is_blank()

  @pending: =>
    instance for instance in @instances when instance.is_pending()

  @processing: =>
    instance for instance in @instances when instance.is_processing()

  # All the ones that we are currently handling....
  @in_progress: => 
    instance for instance in @instances when instance.is_processing() || instance.is_pending()
  
  @uploads_pending: =>
    instance for instance in @instances when instance.is_pending() && instance.type == "file"

  @uploads_processing: =>
    instance for instance in @instances when instance.is_processing() && instance.type == "file"

  @uploads_in_progress: =>
    instance for instance in @instances when (instance.is_processing() || instance.is_pending()) && instance.type == "file"

  @processing_upload: (file_uri) =>
    (instance for instance in @uploads_in_progress() when instance.params.other_params.tmp_file_uri is file_uri).length > 0

  # Flush all pending items
  @flush_queue: =>
    for instance in @pending()
      instance.run()

  @clear_all: =>
    for instance in @instances
      if instance.is_processing()
        instance.abort()
      else if instance.is_pending() and instance.error_callback
        instance.error_callback(false)
      instance.clear()
    @save_instances()
    @clear_timer()

  @check_network_timer: null
  # In seconds
  @check_network_timer_value: null

  @update_timer_value: =>
    if @check_network_timer_value
      @check_network_timer_value  = 1.5*@check_network_timer_value
      if @check_network_timer_value > 300 then @check_network_timer_value = 300
      @check_network_timer_value
    else
      @check_network_timer_value  = 2

  # This is not great because anyone can set the timer and we don't really know if the
  # timer has expired or not (javascript doesn't provide it), so we clear the timer and
  # reset it anyway
  @set_timer: =>
    @update_timer_value()
    window.clearTimeout(@check_network_timer) if @check_network_timer
    Logger.log("Setting check network timer with value of " + @check_network_timer_value)
    @check_network_timer = window.setTimeout(@check_connectivity,@check_network_timer_value*1000)

  @clear_timer: =>
    if @check_network_timer
      window.clearTimeout(@check_network_timer) 
      Logger.log("NetworkHandler: Clearing timer")
    @check_network_timer = null 
    @check_network_timer_value = null

  @status: =>
    ["Processing[#{@processing().length}]:\n  " + (@processing().map (nh) -> "#{nh.type}: #{nh.params.url}").join("\n  "),
     "Pending[#{@processing().length}]:\n  " + (@pending().map (nh) -> "#{nh.type}: #{nh.params.url}").join("\n  "),
     "Free[#{@free().length}]"
    ].join("\n")
    # "Fr(#{@free().length}) Pe(#{@pending().length}/u#{@uploads_pending().length}) Pr(#{@processing().length}/u#{@uploads_processing().length})"

  @store_status: =>
    if (uploading = @uploads_processing().length) > 0
      "Uploading photos [#{uploading}]"
    else if (uploading = @uploads_pending().length) > 0
      "Uploads pending [#{uploading}]"
    else 
      messages = (processing.status_message for processing in @processing() when processing.status_message && processing.status_message.length > 0)
      if messages.length > 0 
        return messages[0] + (if messages.length > 1 then "..." else "")
      else
        ""

  @update_status_message: =>
    $(".network_status_text").html(@store_status())  

  ##########################
  # Instances
  ##########################

  # Instance variables
  # we save the parameters so we can send later
  status: null
  type: null
  params: {}
  attempt_count: 0
  error_callback: null
  success_callback: null
  upload_progress_callback: null

  setup: (params) ->
    @type = if params.file then "file" else "ajax"

    @error_callback = params.error
    @success_callback = params.success
    @upload_progress_callback = params.progress

    @status_message = params.message
    @id = params.id unless @id? 

    params.error = @error
    params.success = @success

    @attempt_count = 0
    @params = params
    if @params.url 
      @params.url = LpUrl.full_url(@params.url)

    # Set the retry count to a large number unless it's been specified
    # We can set this to 0 if we don't want to retry by default
    # or to a large number if we want to retry
    params.retry_count = 50 unless params.retry_count || params.retry_count == 0

  #  url: the target URL to upload to
  #  file: the filename or file object that we're sending (if this is a file transfer)
  #  success: the function to call if successful
  #  error: the function to call if there was an error
  #  retry_count: the default retry count - set to 0 if no retries desired
  constructor: (params) -> 
    @setup(params)
    # @nh_id = Math.floor((Math.random()*100000)+1);

  is_free: -> @status == null 
  is_pending: -> @status == "pending"
  is_processing: -> @status == "processing"

  update_status: (status) ->
    @status = status
    NetworkHandler.update_status_message()

  clear: ->
    # Logger.log("Freeing up network handler "+@log_info())
    @update_status(null)
    @params = {}
    @type = ""
    @attempt_count = 0
    @error_callback = null
    @success_callback = null
    @status_message = null
    window.clearTimeout(@timer) if @timer
    @timer = null
    # @upload_progress_callback = null

  abort: ->
    @retry_count = 0
    if @jqXHR
      @jqXHR.abort() 
    else
      # For file uploads, we can't abort and have it drop into the error condition so we'll just 
      # call the error callback and bail
      @error_callback(false) if @error_callback 

  upload_progress: (progressEvent) =>
    @update_time = (new Date).getTime()
    if progressEvent.lengthComputable
      percent = (progressEvent.loaded * 100.0 / progressEvent.total).toFixed()
      if @upload_progress_callback
        @upload_progress_callback(percent)
    else
      Logger.log("Got progress event but length was not computable")

  # Defacto success and error callbacks
  success: (response) =>
    Logger.log("NetworkHandler success: #{@log_info()} (#{now() - @start_time}ms)" )
    if @type == "file" 
      # Logger.log "NetworkHandler: finished transferring file  #{@params.file}"
      # Logger.log "NetworkHandler: file transfer response = "
      # Logger.log(response.response)
      # Logger.log("NetworkHandler: params = ")
      # Logger.log(@params)
      if Config.is_running_on_device() && @params.dataType && @params.dataType.match(/json/i)
        # If we are sending a file, the repsonse is not a json object but the actual xttp response with has a response inside it, 
        # which is itself a stringified json object, so we need to address that.  I think the decodeURIcomponent was for handling urls
        # that were passed.  We are doing this as a convenience for calling functions
        response = JSON.parse decodeURIComponent(response.response)
        # response = r
        Logger.log(response)

    # Make sure we save the callback before we clear the instance
    callback = @success_callback
    @clear()
    # If there was a timer to check network settings, then we can clear it but better not, so that
    # when it expires we can flush the queue and do everything necessary if the server is OK
    # NetworkHandler.clear_timer()
    NetworkHandler.save_instances()
    if callback
      # Logger.log("NetworkHandler: calling success callback function for #{@params.url}")
      callback(response) 

  # Calling error just returns a function.  To call it manually you need to 
  # call it with @error().call()
  error: (errorObject, textStatus, errorThrown) =>   
    hopeless = false 
    if @type is "file"
      Logger.error("NetworkHandler#{@log_info()}: called local error callback code #{errorObject && errorObject.code}")
      if errorObject and errorObject.code == FileTransferError.FILE_NOT_FOUND_ERR
        hopeless = true
    else
      jqXHR = errorObject
      Logger.error("NetworkHandler#{@log_info()}: called local error callback with '#{textStatus}' #{JSON.stringify(errorThrown)}")
      Logger.log jqXHR
    
    NetworkHandler.add_server_error(@params.url)

    # The server returns a 401 status if there is no current user 
    # We need to check the user to make sure 
    # GARF: This shouldn't be in this deep into the network handler but I don't have
    # time to refactor a higher-layer service to do this.  It's pretty bad
    # for this low-level service to be accessing current_user()...
    if jqXHR && jqXHR.status == 401 && current_user_id()
      Logger.warn("Got a 401 message so will try to checkin")
      $.ajax {
        url: Config.base_url() + "/app/checkin"
        data: {id: current_user_id(), v: Config.version, p: Config.platform(), pv: Config.platform_version(), pt:push_device_token()}
        async:false
        success: (data) =>
          Logger.log "Checkin succeeded for user #{current_user_id()}"
          @run()
        error: (jqXHR, textStatus, errorThrown) ->
          Logger.log("Checkin failed with error " + textStatus + ":" + errorThrown)
      }
      @update_status("pending")
      return

    # Make sure we save the callback before we clear the instance
    callback = @error_callback
    # If we are retrying no need to call the error handler (unless I create a callback for "on_retry")
    if @attempt_count < @params.retry_count and not hopeless
      @attempt_count +=1 
      NetworkHandler.set_timer()
      @update_status("pending")
    else
      @clear()
    NetworkHandler.save_instances()
    if callback
      fail_status = if @is_pending() then NetworkHandler.FAIL_STATUS.WILL_RETRY else if hopeless then NetworkHandler.FAIL_STATUS.HOPELESS else NetworkHandler.FAIL_STATUS.FAILED
      Logger.log("Calling back the error callback function w/ fail status "+fail_status) 
      callback(fail_status, errorObject,textStatus,errorThrown) 

  do_upload_file:  => 
    if Config.is_running_on_device()
      fu_options = new FileUploadOptions()
      fu_options.fileKey= "file"
      fu_options.mimeType= @params.mime_type 
      # file_uri = if typeof(@params.file) is "string" then @params.file else @params.file.toURL()
      file_uri = if typeof(@params.file) is "string" then @params.file else @params.file.fullPath
      fu_options.fileName = file_uri.substr(file_uri.lastIndexOf('/')+1)
      fu_options.params = @params.other_params
      fu_options.chunkedMode = false # Per cordova documentation about android quirks.
      
      Logger.log("NetworkHandler: Transferring file "+file_uri)
      ft = new FileTransfer();
      ft.onprogress =  @upload_progress
      ft.upload(file_uri, @params.url, @params.success, @params.error, fu_options, true);
    else
      # This is a bit hokie.  Better would be to actually upload a file, but let's leave it as it is
      $.ajax {
        url: @params.url
        data: @params.other_params
        type: "post"
        success: @params.success
        error: @params.error
      }
 
  # This only runs the method if it's not already queued to be run
  duplicate_request: =>
    dupe = false
    for instance in NetworkHandler.in_progress()
      if instance.id isnt @id && instance.params.url == @params.url && instance.params.data == @params.data 
        Logger.warn("NetworkHandler not queueing request for #{@params.url} because it's already queued")
        dupe = true
        break
    dupe

  # Returns self
  run: =>
    Logger.log("NetworkHandler #{@log_info()} running")
    @update_status("pending")
    if NetworkHandler.check_network()
      @update_status("processing")
      # Mark the start time in milliseconds
      @start_time = now()
      @update_time = now()
      @timer = window.setTimeout(@check_for_hung_status, if @type == "ajax" then NetworkHandler.AJAX_TIMEOUT else NetworkHandler.FILE_TIMEOUT)
      if @type == "ajax"
        if (@duplicate_request())
          @clear()
        else
          @jqXHR = $.ajax(@params)
      else
        @do_upload_file(@params)
    else 
      # FF 2013-06-29: Not sure if we want to run error in this case.  I think this was added, but if we have no network
      # is it really an error?  The benefit is that it stays in the queue for later processing
      @error()
    @


  # called if the processing is hung
  check_for_hung_status: =>
    return unless @is_processing()

    now = (new Date).getTime()
    timeout = if @type == "ajax" then NetworkHandler.AJAX_TIMEOUT else NetworkHandler.FILE_TIMEOUT
    if now - @update_time >= timeout
      Logger.error("Oh oh - aborting hung NetworkHandler #{@id} type #{@type} #{@id} for url #{@params.url}")
      @abort()
    else
      @timer = window.setTimeout(@check_for_hung_status,10000)

  log_info: ->
    "[#{@id}]: #{@type} (#{@params.url})"

