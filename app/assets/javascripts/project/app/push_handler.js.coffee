# Responsible for handling push services
class window.PushHandler

  @init: ->
    if NetworkHandler.network_ok() and Config.is_running_on_device()
      @initPushwoosh()
      

  @saveDeviceToken: (token) =>
    set_push_device_token(token)
    NetworkHandler.instance(
      url: "push_device_token"
      data: {token: token, id: current_user_id()}
      type: "post"
      retry_count: 0,
      method: "post"
    ).run()


  @reset_icon: =>
    if Config.is_ios_device()
      window.plugins.pushNotification.setApplicationIconBadgeNumber(0)
      
  @initPushwoosh: =>
    # pushNotification is the javascript handle to our plugin
    pushNotification = window.plugins.pushNotification;
    if not pushNotification
      Logger.warn("No Push notification plugin")
      return 

    Logger.log("Initializing Pushwoosh")
 
    # If we succeed at registering the device, 
    if Config.is_ios_device()
      config = {alert:true, badge:true, sound:true, pw_appid:"688D6-F0591", appname:"LivingPic"}
    else
      config = { projectid: "926360415491", appid : "688D6-F0591" }

    pushNotification.registerDevice(config,
      ((status) =>
        if Config.is_android()
          deviceToken = status
        else
          deviceToken = status['deviceToken']
        Logger.log('registerDevice: ' + deviceToken)
        @saveDeviceToken(deviceToken)
      ),

      ((status) ->
          Logger.warn('failed to register : ' + JSON.stringify(status))
            # navigator.notification.alert(JSON.stringify(['failed to register ', status]))
      )
    )
        
    # Re-init the application badge number - that is, we assume everything has been read - not sure this is the right thing to do or not
    if Config.is_ios_device()
      pushNotification.setApplicationIconBadgeNumber(0);
 
    document.addEventListener('push-notification', ((event) ->
        notification = event.notification
        window.last_push_notification = notification
        # navigator.notification.alert(notification.aps.alert)
        if notification
          Logger.log("Notification = "+JSON.stringify(notification))
          if Config.is_ios_device()
            pushNotification.setApplicationIconBadgeNumber(0)
            userData = notification.u
          else
            userData = JSON.parse(notification.u)
          context_id = userData.c
          Logger.log("Push notification context id = "+context_id)
          if context_id
            window.handle_launch_directive({type: MessageHandler.DIRECTIVE.CONTEXT,id: context_id})
        else
          Logger.error("Notification was NULL")
      )
    )
