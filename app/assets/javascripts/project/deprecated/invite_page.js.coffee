# This hs handles the animations for the page invite.mobile. See invite_page.css for effects.
$(document).ready ->
  # Show what we have
  $("#invite").on "pagebeforeshow", ->
    console.log("Preparing the autocomplete for invites")
    Contacts.full_list( (full_list) ->
      new AutoComplete( page_id: "invite", full_list: full_list )
      $.mobile.changePage("#invite")
      # This is a little hack for testing the invite via the shortcuts page - should be harmless in a real setting
      ensure_current_occasion()
    )
  
$(document).ready -> 
  $("#invite").bind "pageshow", (event) ->
    $("#invite .current_occasion").html current_occasion().name
    $("#invite .auto_complete_picked_items_box").html ""
    $("#invite .help").show()
    
   
window.invite_done = ->
  if AutoComplete.INSTANCE.picked_ids().length > 0 
    console.log("picked keys = " + AutoComplete.INSTANCE.picked_ids())
    contacts = Contacts.find_contacts_by_ids( AutoComplete.INSTANCE.picked_ids() )
    for contact in contacts
      current_occasion().participants.push({first_name: contact.name.givenName, last_name: contact.name.familyName})
    NetworkHandler.instance({    
      url: Config.base_url() + "/invite"
      async: false
      type: "POST"
      data: invitees: JSON.stringify(Contacts.find_contacts_by_ids( AutoComplete.INSTANCE.picked_ids() )), occasion_id:current_occasion().id
      error: -> $.mobile.changePage("#network_error")
      success: (r) -> 
        occ = Occasion.update(r) or $.error "Could not update occasion in Occasions after addParticipants for occasion_id = #{occ.id}"
        set_current_occasion(occ)
    }).run()
    
  $.mobile.changePage("#what_next")    
    
