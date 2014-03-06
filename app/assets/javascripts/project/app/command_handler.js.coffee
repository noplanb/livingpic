class window.CommandHandler

  @get_command: =>
    NetworkHandler.instance({
      url: "/app/remote_command"
      method: "get"
      data: {app_info: app_info()}
      retry_count: 0
      dataType: "json"
      success: @process
    }).run()

  # Process the command that is provided as a json parameter
  @process: (json) =>
    Logger.log("CommandHandler processing json "+JSON.stringify(json))
    switch json.command
      when "send_log" then @send_log(json)
      when "clear_log" then @clear_log(json)
      when "clear_photos" then @clear_photos(json)
      else
        console.log("Error interpreting remote command")

  @send_log: (json) =>
    Logger.upload()

  @clear_log: (json) =>
    Logger.reset()

  @clear_photos: (json) =>
    Photo.remove_all_files()
