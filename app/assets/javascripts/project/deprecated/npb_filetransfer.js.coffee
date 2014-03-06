# MARK FOR DELETION
class window.Foobar
  @success: (result) => console.log result
  @error: (err) => console.log err
  @foo: (str) => cordova.exec(Foobar.success, Foobar.error, "Foobar", "foo", [str])


# Given an absolute file path, uploads a file on the device to a remote server
# using a multipart HTTP request.
# @param filePath String           Full path of the file on the device
# @param server String             URL of the server to receive the file
# @param successCallback (Function  Callback to be invoked when upload has completed
# @param errorCallback Function    Callback to be invoked upon error
# @param options FileUploadOptions Optional parameters such as file name and mimetype
# @param trustAllHosts Boolean Optional trust all hosts (e.g. for self-signed certs), defaults to false

class window.NpbFileTransfer
  
  # =================
  # = Class Methods =
  # =================
  @instances = []
  
  @instance: (filePath, server, successCallback, errorCallback, options, trustAllHosts) =>  
    instance = new NpbFileTransfer(arguments)
    @instances.push instance
    console.log("Creating new NpbFileTransfer instance.  Instances count =  " + @instances.length)
    return instance
  
  @garbage_collection: () =>
    NpbFileTransfer.instances = NpbFileTransfer.instances.filter (i) -> i.status isnt "done"
  
  # ===============
  # = Constructor =
  # ===============
  constructor: (args) ->
    @filePath = args[0]
    @server = args[1]
    
    if !@filePath || !@server
      return throw new Error "FileTransfer.upload requires filePath and server URL parameters at the minimum." 
    
    @status = "processing"
    
    @successCallback = args[2]
    @errorCallback = args[3]
    @options = args[4]
    @trustAllHosts = args[5]
    
    @fileKey = null
    @fileName = null
    @mimeType = null
    @params = {}
    @chunkedMode = true
    @headers = null
  
    if @options?
      fileKey = @options.fileKey
      fileName = @options.fileName
      mimeType = @options.mimeType
      headers = @options.headers
      chunkedMode = @options.chunkedMode if @options.chunkedMode?
      params = @options.params if @options.params?
  
  
  # ====================
  # = Instance Methods =
  # ====================   
  upload: =>
    if cordova?
      cordova.exec(@success, @error, 'NpbFileTransfer', 'upload_tst_err', [@filePath, @server, @fileKey, @fileName, @mimeType, @params, @trustAllHosts, @chunkedMode, @headers]) 
    else   
      (new FTest).test_exec_success(@success, @error, 'NpbFileTransfer', 'upload', [@filePath, @server, @fileKey, @fileName, @mimeType, @params, @trustAllHosts, @chunkedMode, @headers])
      (new FTest).test_exec_error(@success, @error, 'NpbFileTransfer', 'upload', [@filePath, @server, @fileKey, @fileName, @mimeType, @params, @trustAllHosts, @chunkedMode, @headers])
      throw new Error "cordova is #{typeof cordova}"
      
  error:(e) => 
    console.log "In NpbFileTransfer.instance.error"
    @status = "done"
    NpbFileTransfer.garbage_collection()
    # error = new FileTransferError(e.code, e.source, e.target, e.http_status)
    @errorCallback(e)
  
  success: (result) => 
    console.log "In NpbFileTransfer.instance.success"
    @status = "done"
    NpbFileTransfer.garbage_collection()
    @successCallback(result)


# =============
# = Test Code =
# =============
class window.FTest
    
  constructor: ->
    
  test_exec_success: (success, error, klass, method, options) -> success(arguments)
    
  test_exec_error: (success, error, klass, method, options) -> error(arguments)

@test_npb_ft = -> NpbFileTransfer.instance("filePath", "server", test_succ_callback, test_err_callback, {fileKey: "fileKey", mimeType: "mimeType"}, true).upload()  

@test_err_callback = (e) ->
  console.log "In Error Callback"
  console.log e
  
@test_succ_callback = (result) ->
  console.log "In Success Callback"
  console.log result