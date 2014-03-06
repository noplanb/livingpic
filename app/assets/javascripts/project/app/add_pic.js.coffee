# This js handles capturing a pic / picking one from gallery / and the animations for the page tag_pic.mobile.
$(document).ready ->
  $("#tag_pic").on "pagebeforeshow", ->
    $(".last_pic_background").css("background-image","url(#{current_picture().pic})") if Config.is_running_on_device()

window.capture_pic = ->
    # Picture.capture(goto_tag_pic_page)
    # goto_tag_pic_page()  # Eliminate tagging for Thanksgiving release.
    LoaderSpinner.blank_page_spinner()
    Picture.capture(capture_pic_success, capture_pic_error)

# Gallery picker now used
# window.pick_pic = ->
#   LoaderSpinner.blank_page_spinner()
#   if Config.is_running_on_device()
#     # Picture.capture(goto_tag_pic_page)
#     Picture.pick(capture_pic_success, capture_pic_error)
#   else
#     # goto_tag_pic_page()  # Eliminate tagging for Thanksgiving release.
#     $.mobile.changePage("#occasion_for_pic")

# No tagging
# window.goto_tag_pic_page = ->
#   Contacts.full_list( (full_list) ->
#     new AutoComplete( page_id: "tag_pic", full_list: full_list )
#     $.mobile.changePage("#tag_pic")
#   )

window.capture_pic_error = ->
  Logger.warn "Picture: no photo captured or picked"
  GalleryController2.show_current()
  
window.capture_pic_success = ->  
  LoaderSpinner.hide_spinner()
  OccasionForPicController.show()