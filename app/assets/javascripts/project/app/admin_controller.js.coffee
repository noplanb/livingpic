class window.AdminController 
  # Show the log file

  @enter: =>
    if @authenticated || UserHandler.have_admin_access()
      @show_main_page()
    else
      @ask_for_auth()

  @exit: =>
    UserHandler.startup()

  @authenticate: =>
    pass = $("#admin_auth_code").val()
    if pass is "lp2013"
      @authenticated = true
      @show_main_page()
    else
      @ask_for_auth()
      # @exit()

  @show_change_host: =>
    Pager.change_page("change_host")

  @change_host: (host) =>
    clear_current_occasion()
    unless host
      host = $("#change_host input").val()
    Logger.log("Admin: changed host to #{host}")
    Config.set_host_url(host)
    @show_main_page()

  @show_log: =>
    Logger.set_callback_for_read @write_log_to_screen
    Logger.cat()

  @shorten_log_date: (line) =>
    line.replace(/(\s201\d)\s(.+)\s*GMT.*?:/gm,'$2:')

  @remove_log_date: (line) =>
    line.replace(/(.*\s201\d)\s(.+)\s*GMT.*?:/gm,'$2:')
          
  @write_log_to_screen: (contents) =>
    lines = contents.split("\n")
    html_lines = []
    odd = false
    for line in lines 
      if line.indexOf("Device is ready") != -1
        style_class = "new_session"
        line = @shorten_log_date(line)
      else if line.indexOf("System resumed") != -1
        style_class = "resumed_session"
        line = @shorten_log_date(line)
      else 
        line = @remove_log_date(line)
        if line.indexOf("ERROR") != -1
          style_class = "error"
        else if line.indexOf("WARN") != -1
          style_class = "warn"
        else if line.indexOf("DEBUG") != -1
          style_class = "debug"
        else
          style_class = if odd then "odd_row" else "even_row"
          odd = not odd
      line = line.replace(/&/g, '&amp;').replace(/>/g, '&gt;').replace(/</g, '&lt;')
      html_lines.unshift("<div class='#{style_class}'>#{line}</div>")

    $("#log_file .contents").html(html_lines.join("\n"))
    Logger.set_callback_for_read null
    Pager.change_page("log_file")

  @clear_log: =>
    Logger.reset()
    @show_main_page()

  @show_main_page: =>
    @show_host_url()
    @show_current_user()
    @show_log_to_console_button_text()
    Pager.change_page("admin")
  
  @show_set_user: =>
    Pager.change_page("set_user")

  @set_user: (user_id) =>
    user_id = $("#set_user_id").val()
    Logger.log("Changing user_id to #{user_id}")
    UserHandler.set_user(user_id,->    clear_current_occasion(); console.log("Changed the user successfully"))
    @show_main_page()

  @reset_user: =>
    UserHandler.reset()
    @show_main_page()

  @ask_for_auth: =>
    Pager.change_page("admin_auth")

  @show_host_url: =>
    $("#admin .current_url").text(Config.base_url())

  @show_current_user: =>
    $("#admin .current_user").text("[#{current_user_id()}] " + current_user().first_name + current_user().last_name)
  
  @show_log_to_console_button_text: =>
    # If it's enabled, button should disable it
    if Config.log_to_console
      $("#admin .log_to_console").text("Disable console Logging")
    else
      $("#admin .log_to_console").text("Enable console Logging")

  @toggle_log_to_console: =>
    Config.log_to_console = not Config.log_to_console
    @show_log_to_console_button_text()

  @restart_weinre: =>
    modjewel.require('weinre/target/Target').main()
