$(document).ready ->
  $("#confirm_invite_details").on("pagebeforeshow", (event) ->
    $("#confirm_invite_details .invitees").html $.toSentence Contacts.first_names(AutoComplete.INSTANCE.picked_ids())
    $("#confirm_invite_details .current_occasion").html current_occasion().name)
