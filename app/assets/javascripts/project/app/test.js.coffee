class window.Test 

  @success_callback: (response) =>
    @alert(response)

  @error_callback: (jqXHR, textStatus, errorThrown) =>
    @alert(errorThrown)

  @alert: (text) ->
    alert(text)
 
  @error401: ->
    NetworkHandler.instance({
      url: "/test/no_user_error",
      async: true,
      retry_count: 0,
      error: (jqXHR, textStatus, errorThrown) =>
        console.log("jqXHR="+jqXHR)
        console.log("textStatus="+JSON.stringify(textStatus))
    }).run()

  @pass: =>
    NetworkHandler.instance({
      url: "/test/pass",
      async: true,
      success: (response) =>
        @success_callback(response)
    }).run()

  @fail_no_retry: =>
    NetworkHandler.instance({
      url: "/test/fail",
      async: true,
      success: (response) =>
        @success_callback(response)
      error: (jqXHR, textStatus, errorThrown) =>
        @error_callback(jqXHR, textStatus, errorThrown)
    }).run()

  @fail_retry: =>
    NetworkHandler.instance({
      url: "/test/fail",
      retry_count: 3,
      async: true,
      success: (response) =>
        @success_callback(response)
      error: (jqXHR, textStatus, errorThrown) =>
        @error_callback(jqXHR, textStatus, errorThrown)
    }).run()

  @upload: =>
    NetworkHandler.instance({
      url: Config.base_url() + "/photos/create"
      retry_count: 20
      file: current_picture().pic, 
      mime_type: "image/jpeg", 
      other_params: {device_state: JSON.stringify(device_state())},
      success: (r) -> 
        alert("Hallelujah")
      error: (jqXHR, textStatus, errorThrown) =>
        @error_callback(jqXHR, textStatus, errorThrown)
    }).run()