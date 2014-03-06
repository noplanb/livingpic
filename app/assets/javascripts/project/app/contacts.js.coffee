class window.Contacts
  
  # Local Storage:
  # This class uses Local Storage variables:
  #   - contacts :: array of ids and names for autocomplete
  #   - contacts_directory :: hash of full records indexed by id 
      
  @prefetch: (options = {}) =>
    Logger.log "Contacts: Prefetching contacts"
    @full_list(options.callback, options) if !contacts() or @is_fresh(options) 
    contacts().length
  
  # Refetch the contacts if the user has already fetched them or given permission to fetch them
  @refresh_if_allowed: =>
    @prefetch({fresh:true}) if has_allowed_contacts()

  @full_list: (callback, options = {}) =>
    if contacts() and not @is_fresh(options)
      callback(contacts()) if callback
      return null
    if Config.is_running_in_browser() then @get_list_from_server(callback) else @get_list_from_device(callback)
  
  @is_fresh: (options) =>
    options.fresh? and options.fresh
         
  @get_list_from_device: (callback) =>
    Logger.log("Loading contacts")
    Contacts.device_call_back = callback    # Use a global here because cant have 2 params for the success callback below.
    navigator.contacts.find(["displayName","name", "phoneNumbers", "emails"], Contacts.handle_list_from_device, Contacts.get_list_error, {multiple:true})
    
  @handle_list_from_device: (cntcts) =>
    set_allowed_contacts()
    Logger.log "Contacts: Successfully found " + cntcts.length + " contacts"
    
    cntcts = Contacts.filter_useful(cntcts)
    Logger.log "Contacts: Filtered down to " + cntcts.length + " useful contacts"
    
    # The iphone doesn't have the display name, so we need to first go and see if we can manufacture one if one is not present
    $.each(cntcts,
      (index,contact)->
        if !contact.displayName 
          if contact.name.formatted then contact.displayName = contact.name.formatted else contact.displayName = contact.name.givenName + " " + contact.name.familyName
    )
    
    # Save the raw contacts in an indexed directory.
    cd  = {}
    cntcts.map (c) => cd[c.id] = displayName:c.displayName, name:c.name, emails:c.emails, phoneNumbers:c.phoneNumbers
    set_contacts_directory cd
    
    set_contacts  cntcts.sort( (a,b) -> $.trim(a.displayName.toLowerCase) < $.trim(b.displayName.toLowerCase) ).map((c) -> id: c.id, str: c.displayName)
    Contacts.device_call_back(contacts()) if Contacts.device_call_back
  
  @filter_useful: (raw_list) =>
    raw_list.filter( (c) -> Contacts.has_phone(c) ).filter( (c) -> Contacts.has_name(c) )
  
  @has_name: (raw_contact) => 
    raw_contact.displayName? || (raw_contact.name and raw_contact.name.formatted isnt "")
  
  @has_phone: (raw_contact) => 
    raw_contact.phoneNumbers? and raw_contact.phoneNumbers.length > 0
    
  @get_list_error: (error) =>
    alert "Contacts: Error loading contacts:" 
    Logger.log error
  
  # Get the contacts from the server if the client is browser.
  #  - Contacts are imported as an array of hashes containing at least id, first_name, last_name, full_name (and of course phones and emails)
  #  - The id is a unique number across the latest import of the contact list it is used in the views to refer to contact records. The id 
  @get_list_from_server: (callback) =>
    Logger.log("Contacts: Getting contacts list from server")
    $.ajax {
      dataType: "json"
      url: Config.base_url() +  "/app/get_contacts"; 
      success: (response) ->
        Contacts.handle_list_from_server(response, callback)
    } 
  
  @handle_list_from_server: (cntcts, callback) =>
    Logger.log("Contacts: Got " + cntcts.length + " contacts from server")
    
    cntcts = Contacts.filter_useful(cntcts)
    Logger.log "Contacts: Filtered down to " + cntcts.length + " useful contacts"
    
    # Save the raw contacts in an indexed directory.
    cd  = {}
    cntcts.filter((c) -> c.displayName?).map (c) => cd[c.id] = c
    set_contacts_directory cd
    
    set_contacts  cntcts.filter((c) -> c.displayName?).sort( (a,b) -> $.trim(a.displayName.toLowerCase()) < $.trim(b.displayName.toLowerCase()) ).map((c) -> id: c.id, str: c.displayName)
    callback(contacts())
    return null
      
  @upload_contacts: (contacts) =>
    $.ajax {
      url: Config.base_url() + "/contacts"
      type: "POST"
      data: {contacts: contacts}
      success: -> alert "sent them ok"
      error: (jqXHR, textStatus, errorThrown) -> alert errorThrown
    }
  
  @like: (str) =>
    return null unless contacts()
    contacts().filter (c) -> c.str.match new RegExp(str,"i") 
    
  @like_details: (str) => 
    Contacts.find_contacts_by_ids Contacts.like(str).map (c) -> c.id
    
  @find_contacts_by_ids: (ids) => 
    ids = to_array(ids)
    ids.map((id) -> contacts_directory()[id])
    
  @first_names: (ids) => @find_contacts_by_ids(ids).map (c) => @contact_first_name(c) 
  @last_names: (ids) => @find_contacts_by_ids(ids).map (c) => @contact_last_name(c) 
  @full_names: (ids) => @find_contacts_by_ids(ids).map (c) => @contact_full_name(c) 
  
  @first_name: (c) => c && c.name && c.name.givenName || ""
        
  @last_name: (c) => c && c.name && c.name.familyName || ""
    
  @full_name: (c) => c && c.displayName || "#{@contact_first_name(c)} #{@contact_last_name(c)}"


