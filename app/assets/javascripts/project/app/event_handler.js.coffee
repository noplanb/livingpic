# For handling noteworthy events from a systems standpoint, such are errors, interesting pages visited, etc.
class window.EventHandler
  @server_logging_on = true

  @show_to_user: (message) =>
    # For now, just show a message via an alert
    alert(message)

  # Expect a hash back
  @log_to_server: (params) =>
    if @server_logging_on and NetworkHandler.network_ok()
      $.ajax({
        url: Config.base_url() + "/app_monitor/log"
        async: true
        type: "post"
        data: $.extend(params,{app_info: app_info()})
      })

