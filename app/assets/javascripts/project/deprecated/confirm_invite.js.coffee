$(document).ready ->
  $("#confirm_invite").on("pagebeforeshow", (event) ->
    $("#confirm_invite .invitees").html $.toSentence Contacts.first_names(AutoComplete.INSTANCE.picked_ids())
    $("#confirm_invite .current_occasion").html current_occasion().name)
