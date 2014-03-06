class window.Filer
  
  @persistent_filer: null
  @temporary_filer: null

  @file_systems: {persistent: null, temporary: null}
  @fs_observers: {persistent: [], temporary: []}

  @init: =>
    Logger.log("Initializing file system")
    if Config.is_running_on_device()
      # Let's ask for 5MB for now.  Will have to increase it.
      if @file_systems.persistent then Logger.log("No need to init persistent FS") 
      else window.requestFileSystem( LocalFileSystem.PERSISTENT, 5*1024*1024, @set_persistent_fs , @error )
      if @file_systems.temporary then Logger.log("No need to init temporary FS") 
      else window.requestFileSystem( LocalFileSystem.TEMPORARY, 0, @set_temporary_fs , @error ) 
    # Only Chrome supports the filesystem api, albeit a bit differently
    # else if navigator.userAgent.match(/chrome/i)
    #   window.requestFileSystem  = window.requestFileSystem || window.webkitRequestFileSystem;
    #   window.requestFileSystem(window.TEMPORARY, 5*1024*1024 , onInitFs, errorHandler);


  # Some methods may require the file system to be ready for their own intitialization
  # They need to register an observer so we call them when the indicated file system is ready
  # values for fs are either "persistent" or "temporary"
  @register_fs_observer: (fs,callback) =>
    list = @fs_observers[fs]
    if not list? 
      Logger.error("Enter either persistent or temporary as the observer type")
      return

    if @file_systems[fs]
      callback(@file_systems.persistent)
      return

    for observer in list
      return true if observer == callback

    # Logger.log("Added callback to list of #{fs} observers")
    list.push(callback)


  @set_persistent_fs: (fs) =>
    @file_systems.persistent = fs
    # Logger.log("Initialized persistent file system.  Root = "+ fs.root.toURL())
    Logger.log("Initialized persistent file system.  Root = "+ fs.root.fullPath)
    for observer in @fs_observers.persistent
      observer(fs)
          
  @set_temporary_fs: (fs) =>
    @file_systems.temporary = fs
    # Logger.log("Initialized temporary file system.  Root = "+ fs.root.toURL())
    Logger.log("Initialized temporary file system.  Root = "+ fs.root.fullPath)
    for observer in @fs_observers.temporary
      observer(fs)

  @error: (code) ->
    alert("Got a Filer error "+JSON.stringify(code))

  # Called when a path is resolved
  @resolved_uri_to_file: (fileEntry) ->
    # Logger.log fileEntry.toURL()
    Logger.log fileEntry.fullPath

  @uri_to_file: (file_uri, path_callback = @resolved_uri_to_file) ->
    window.resolveLocalFileSystemURI(file_uri, path_callback, @error);

  @persistent: ->
    @persistent_filer ||= new Filer ("persistent")
  
  @temporary: ->
    @temporary_filer ||= new Filer ("temporary")
  
  

  #####################
  # Instance methods
  #####################
  
  # Create a new filter with either persistent or temporary file systems
  constructor: (kind = "persistent") ->
    # I should be able to reference constructor here instead of Filer but it doesn't work...
    @fs = if kind == 'temporary' then Filer.file_systems.temporary else Filer.file_systems.persistent
    @current_directory = @fs.root

  root: => 
    @fs? and @fs.root
  
  root_path: =>
    # @root() and @root().toURL()
    @root() and @root().fullPath
   
  error: (code) =>
    alert("Got a Filer error "+JSON.stringify(code))

  # We expect a file path not a URL
  file_exists: (file_path, true_callback, false_callback) =>
    @fs.root.getFile(file_path, {create: false}, true_callback, false_callback)

  ls: (rel_path) =>
    if rel_path?
      @current_directory.getDirectory(rel_path, {create:false}, @ls_gd_success, () -> Logger.log "'#{rel_path}' is not a directory.")
    else 
      @ls_gd_success(@current_directory)
      
  ls_gd_success: (directory) => 
    dr = directory.createReader()
    dr.readEntries( @print_ls )

  print_ls: (r) =>
    dirs = {}
    files = {}
    for obj in r
       dirs[obj.name] = obj if obj.isDirectory
       files[obj.name] = obj if obj.isFile
     str = "DIRECTORIES:"
     str += "\n#{dir}" for dir in keys(dirs).sort() 
     str += "\n\nFILES:"       
     str += "\n#{fl} - #{files[fl].fullPath}" for fl in keys(files).sort()
     # str += "\n#{fl} - #{files[fl].toURL()}" for fl in keys(files).sort()
     Logger.log str

  cd: (rel_path) =>
    if rel_path is ".."
      # @current_directory.getParent(Filer.INSTANCE.cd_gd_success, () -> Logger.log "Parent of '#{@current_directory.toURL()}' is not a directory.")
      @current_directory.getParent(Filer.INSTANCE.cd_gd_success, () -> Logger.log "Parent of '#{@current_directory.fullPath}' is not a directory.")
    else
      @current_directory.getDirectory(rel_path, {create:false}, Filer.INSTANCE.cd_gd_success, () -> console.log "'#{rel_path}' is not a directory.")
    
  cd_gd_success: (directory) => 
    @current_directory = directory
    # Logger.log "Changed directory to " + @current_directory.toURL()   
    Logger.log "Changed directory to " + @current_directory.fullPath   
    