# ================
# = Device State =
# ================
# By Sani:
# For posting data to the server I am adopting the the following convention:
# Rather than designing the customizing the data object for each post in general just send the DeviceState object
# which should always include the relevant objects.
# The server can pick out what it needs based on the controller method that was called. 
# This has a number of benefits.
#   - It standardizes the datastructure going back to the server and encapsulates it all in one place here.
#   - The additional data may be useful for analysis and debugging in the field later.
#   - It is just so much easier than customizing each of the ajax posts separately. 
# 
#  I have not gone back and made each post work with this convention but will try to use it going forward.
#  I will convert existing posts only if I find myself editing them for some other reason. 
# FF: 
#  Agreed, but I'm using this selectively b/c it makes the logs really hard to read
# DEPRECATED - THIS is really inefficient and not terribly useful
@device_state = ->
  {
    user: current_user()
    occasion: current_occasion()
    contacts: if AutoComplete.INSTANCE? then Contacts.find_contacts_by_ids(AutoComplete.INSTANCE.picked_ids()) else false
    location: current_location()
    picture: current_picture()
    app_version: Config.version
    network: NetworkHandler.network_status(),
  }

# FF says: 
# Create a minimum set of parameters that are easier to read, and use them in the 
# event handling, etc., at least until Sani shows me the way w/ splunk and I am no longer
# intimidated by very hard to read log files
@app_info =  ->
  { 
    user_id: current_user().id,
    network: NetworkHandler.network_status(),
    current_occasion: {id: current_occasion().id, name: current_occasion().name }
    app_version: Config.version,
    is_running_in_browser: Config.is_running_in_browser()
    platform: Config.platform,
    version: Config.version
  }

$(document).on "npb_pageshow", (event,page) -> 
  if page && Config.log_pages && Boot.booted
    # console.log("Firing pagebeforechange event for "+u.hash)
    EventHandler.log_to_server({type: "page", value: page})
  true

