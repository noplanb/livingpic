# MARK FOR DELETION
# Trying to figure out the conventions we should use with moving dates back and forth from the server and storing and retrieving from local storage
# on the device. 
# 
# See docs/sani/date_hell.txt

window.DateTest = {
  get_date: ->
    $.ajax {
      url: "/app/test_get_date"
      success: (r) -> DateTest.result = r
    }
  
  post_date: ->
    $.ajax {
      type: "POST"
      url: "/app/test_post_date"
      data: {test_date: new Date}
    }
}

window.test_null = -> 
  $.ajax {
    data: "a": null
    type: "POST"
    url: "/app/test"
  }