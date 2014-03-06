class window.Logger

  @writer:null
  @reader: null
  @file_entry: null

  # Set this to debug if you want to see debug messages
  @level = "debug"

  @buffer: ""

  # subscribe to the Filer so we're notified when the permanent file system is available
  @init: =>
    console.log("Initializing Logger")
    Filer.register_fs_observer("persistent",@setup_log_file_entry)

  @setup_log_file_entry: (fs) =>
    fs.root.getFile("log.log",{create:true},@got_file_entry,@file_entry_fail)

  @got_file_entry: (file_entry) =>
    @log("Logger got file entry for log file")
    @file_entry = file_entry
    # Create a log writer for this file entry so that I can log messages
    @file_entry.createWriter(@got_writer,@writer_fail)
    @file_entry.file(@check_file_size,@file_fail)

  @file_entry_fail: =>
    alert("Logger: Unable to create the log file")

  @writer_fail: =>
    alert("Logger: Unable to create the writer")

  @file_fail: (e)=>
    alert("Logger: Unable to get the log file w/ error "+JSON.stringify(e))

  @got_writer: (writer) =>
    @writer = writer
    @writer.seek(-1)
    # @writer.onwriteend = => @buffer = ""

  # Limit the file size to 100K. If it gets bigger than that, truncate it
  # TODO - we may want to send it to the server and then truncate it
  @check_file_size: (file) =>
    @log("Logger file size = "+file.size)
    if file.size > Config.max_log_file_size
      try
        # For some reason we get an exception when we try to reset the log file immediately, so wait a bit...
        window.setTimeout(@reset,1000)
      catch e
        @log("Tried to reset the log file but got an exception")
      
      @warn("Reset the log because it was too big")

  @reset: =>
    @writer.truncate(0) if @writer

  @upload: =>
    @flush()
    @log("Sending log file back to server")
    if Logger.file_entry
      NetworkHandler.instance({
        url: "/app/upload_log"
        retry_count: 0
        # file: Logger.file_entry.toURL(),
        file: Logger.file_entry.fullPath,
        other_params: {app_info: app_info() }
        success: -> alert("Uploaded the log file")
        error: -> alert("Upload failed")
      }).run()

  @log: (message) =>
    console.log(message) if not Config.store_release() or Config.log_to_console
    # console.log(message) 
    date = (new Date).toString()
    message = JSON.stringify(message) unless typeof message == "string"
    log_message = @buffer + date + ": " + message+"\n"
    @buffer = ""
    if @writer  && (@writer.readyState isnt FileWriter.WRITING)
      @writer.write(log_message)
    else 
      @buffer += log_message

  @error: (message) =>
    @log("ERROR - #{message}")

  @warn: (message) =>
    @log("WARN - #{message}")
    
  @debug: (message) =>
    @log("DEBUG - #{message}") if @level is "debug"

  @flush: =>
    if @writer  && (@writer.readyState isnt FileWriter.WRITING) && @buffer
      @writer.write(@buffer)

  @read: (file) =>
    # console.log("Reading the log file of size #{file.size}")
    @reader = new FileReader()
    @reader.onloadend = (evt) => if @read_callback then @read_callback(evt.target.result) else console.log(evt.target.result)
    @reader.readAsText(file)    

  @set_callback_for_read: (callback) =>
    @read_callback = callback

  # Cat the log file
  @cat: =>
    @flush()
    @file_entry.file(@read,@file_fail)

