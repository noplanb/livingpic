# This hs handles the animations for the page add_participants2 See invite_page.css for effects.
class window.AddParticipants2
    
  constructor: (occasion = current_occasion()) ->
    AddParticipants2.INSTANCE = @
    @occasion = occasion
    @init_page()
    @set_up_auto_complete()
  
  init_page: => 
    $("#add_participants2 .current_occasion").html @occasion.name
    $("#add_participants2 .auto_complete_picked_items_box").html ""
    $("#add_participants2 .help").show()
    $("#add_participants2 .auto_complete_search_input_field").attr("placeholder", "Type a name")
    
  set_up_auto_complete: =>
    LoaderSpinner.show_spinner()
    Contacts.full_list @contacts_callback
  
  contacts_callback: (full_list) =>
    @auto_complete = new AutoComplete2( page_id: "add_participants2", full_list: full_list, theme: "a" )
    LoaderSpinner.hide_spinner()
    Pager.change_page "add_participants2"
  
  cancel: =>
    GalleryController2.show_current()
    
  done: =>
    if AutoComplete2.INSTANCE.none_picked()
      ParticipantsView2.render_highlight_added([])
      GalleryController2.show_current()
    else
      contacts = Contacts.find_contacts_by_ids( AutoComplete2.INSTANCE.picked_ids() ).map (c) -> {
        first_name: Contacts.first_name(c).capitalize_words()
        last_name: Contacts.last_name(c).capitalize_words()
      }
      current_occasion().add_participants(contacts)
      current_occasion().save()
      ParticipantsView2.render_highlight_added(contacts)
      GalleryController2.show_current()
      $.ajax {    
        url: Config.base_url() + "/invite"
        type: "POST"
        data: invitees: JSON.stringify(Contacts.find_contacts_by_ids( AutoComplete2.INSTANCE.picked_ids() )), occasion_id:@occasion.id
        error: -> Pager.change_page "network_error"
        success: (r) -> Occasion.update(r) or $.error "Could not update occasion in Occasions after addParticipants for occasion_id = #{occ.id}"
        }


