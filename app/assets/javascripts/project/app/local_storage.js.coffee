# For our purposes we assume all browsers can only use strings in local storage.
# we will therefore save JSONs rather than objects
class window.appState
  @set: (key, obj) ->
    if obj?
      try
        localStorage[key] = JSON.stringify(obj)
      catch error
        alert "Could not set appState for #{key} because of #{error}"
    else
      @clear key 
  
  @get: (key) ->
    result = false
    try
      result = if localStorage[key]? then JSON.parse(localStorage[key]) else false #get rid of null and undefined so we can do easy tests.
    catch error
      alert error 
    result 
    
  @clear: (key) ->
    localStorage.removeItem(key)
    
  @clear_all: ->
    localStorage.clear()
    
  # Test local storage size:
  @tls: {
    mk_str: (size) => 
      str = ""
      str += "a" for n in [0..size]
      str
  
    test: (size) =>
      localStorage.clear()
      localStorage.test = appState.tls.mk_str size
      return localStorage.test.length
  }


# ===================
# = Session Methods =
# ===================

@current_user = -> appState.get("current_user")
@set_current_user = (obj) -> 
  appState.set("current_user", obj)
  UserHandler.checkin()
@clear_current_user = -> appState.clear("current_user")
@current_user_id = -> current_user() and current_user().id
@current_user_fullname = -> "#{current_user().first_name or ''} #{current_user().last_name or ''}"

@registered = -> @current_user().registered
@set_registered = -> 
  u = current_user()
  u.registered = true  # Note this works fine in JS even if user is false.
  set_current_user(u)
# Used for testing only.
@clear_registered = ->
  u = current_user()
  u.registered = false
  set_current_user(u)

# These device tokens are used for push notification
@set_push_device_token = (value) -> appState.set("push_device_token",value)
@push_device_token = -> appState.get("push_device_token") || null

# This is just a cache of the current occasion in the dom so we don't have to hit storage each time
@dom_current_occasion = null

@current_occasion_id = -> appState.get("current_occasion_id")
@set_current_occasion_id = (id) -> appState.set("current_occasion_id",id)

# current_occason will try to ensure consistency.  If we somehow have a current_occasion_id() that is messed up (e.g. occasion deleted, which
# happens in testing) it will set up the current_occasoin to the last occasion.  
@current_occasion = -> 
  @dom_current_occasion || 
  if @current_occasion_id() && occasion = Occasion.find(@current_occasion_id())   
    @dom_current_occasion = occasion
  else 
    occasion = Occasion.last()
    @set_current_occasion(occasion)
    occasion || false


@ensure_current_occasion = ->
  set_current_occasion(Occasion.most_recent()) unless current_occasion()

@set_current_occasion = (obj) -> 
  @dom_current_occasion = obj
  @set_current_occasion_id(obj && obj.id)

@clear_current_occasion = ->  @set_current_occasion(null)
  
# Define this becuase .name is a javascript keyword and breaks when you use it in the views. Coffee doesnt have that problem.
@current_occasion_name = -> if current_occasion()? && current_occasion.name? then current_occasion().name else ""

@current_location = ->
  cl = GeoLocation.lat_long()
  # I'm just going to assume the person is not traveling at the speed of light and will just update the location
  # only when the app starts or resumes
  # GeoLocation.get_location()   # Keep it fresh by refreshing after every time it is requested.
  cl
  
# Saved as an array of records which include a unique id field and ar presorted by fullname for quick display.
@contacts = -> appState.get("contacts")
@set_contacts = (obj) -> appState.set("contacts", obj)
@clear_contacts = -> appState.clear("contacts")
# The above would be a good proxy for this but I think we don't really care about
# saving the full contact list anymore
@has_allowed_contacts = -> appState.get("allowed_contacts")
@set_allowed_contacts = -> appState.set("allowed_contacts",true)

# Saved as a hash with id as the index. For quick retrieval of specific contact records. 
@contacts_directory = -> appState.get("contacts_directory")
@set_contacts_directory = (obj) -> appState.set("contacts_directory", obj)
@clear_contacts_directory = -> appState.clear("contacts_directory")


@display_app_state = -> "Current_user: #{current_user_id()} | Registered: #{registered()}"

# Local storage DB version.  This is used in data migrations as we update the code and want to make sure
# that we can handle the data
@db_version = -> appState.get("db_version")
@set_db_version = (version) -> appState.set("db_version",version)
@clear_db_version = -> appState.clear("db_version")

# ===============
# = Convenience =
# ===============
@current_picture = -> Picture.last()

# Moved device_state() to monitor.js so we can keep this file localized to storage only

# Related to the current host so we know if we've changed hosts and can clear the local data.  Should only happen in our testing.
@set_host = -> appState.set("host",Config.base_url())
@host_url = -> appState.get("host")
@changed_host = -> @host_url()? && (Config.base_url() isnt @host_url())

# Clear everything
@clear_local_data = ->
  Logger.log("Clearing all app data")
  @dom_current_occasion = null
  appState.clear_all()
  clear_current_occasion()
  Occasion.clear_all()
  Photo.clear_all()
  Photo.cleanup()
  

