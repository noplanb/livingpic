class window.NotificationGen
  @gen: (form) => 
    console.log form
    console.log form.serialize()
    $.ajax({
      url: "/admin/notification_gen"
      type: "POST"
      data: form.serialize()
      success: (r) -> 
        form.find(".result").html r
    })