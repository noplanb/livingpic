# This hs handles the animations for the page add_participants See invite_page.css for effects.
class window.AddParticipants
  
  @INSTANCE: null
  
  constructor: (occasion = current_occasion()) ->
    AddParticipants.INSTANCE = @
    @occasion = occasion
    @init_page()
    @set_up_auto_complete()
  
  init_page: => 
    $("#add_participants .current_occasion").html @occasion.name
    $("#add_participants .auto_complete_picked_items_box").html ""
    $("#add_participants .help").show()
    $("#add_participants .auto_complete_search_input_field").attr("placeholder", "Type a name")
    
  set_up_auto_complete: =>
    LoaderSpinner.show_spinner()
    Contacts.full_list( (full_list) ->
      LoaderSpinner.hide_spinner()
      new AutoComplete( page_id: "add_participants", full_list: full_list, theme: "a" )
      $.mobile.changePage("#add_participants")
    )
  
  cancel: =>
    # FF: I have found this to be really irritating so commeting out for now to see how it feels
    # FlashNotice.flash("Nobody added")
    GalleryController.show(current_occasion())
    
     
  done: =>
    # console.log("picked keys = " + keys(AutoComplete.INSTANCE.picked_items()))
    if AutoComplete.INSTANCE.none_picked()
      FlashNotice.flash("Nobody added")
      GalleryController.show(current_occasion())
    else
      LoaderSpinner.show_spinner()
      contacts = Contacts.find_contacts_by_ids( AutoComplete.INSTANCE.picked_ids() )
      for contact in contacts
        current_occasion().participants.push({first_name: contact.name.givenName, last_name: contact.name.familyName})
      GalleryController.show(current_occasion())
      $.ajax {    
        url: Config.base_url() + "/invite"
        type: "POST"
        data: invitees: JSON.stringify(Contacts.find_contacts_by_ids( AutoComplete.INSTANCE.picked_ids() )), occasion_id:@occasion.id
        error: -> $.mobile.changePage("#network_error")
        success: (r) -> 
          occ = Occasion.update(r) or $.error "Could not update occasion in Occasions after addParticipants for occasion_id = #{occ.id}"
          set_current_occasion(occ)
          FlashNotice.flash("You have invited #{AutoComplete.INSTANCE.picked_item_names().join(', ')} to participate in this album.", "Nicely Done!")
          # GalleryController.show(current_occasion())
        }


