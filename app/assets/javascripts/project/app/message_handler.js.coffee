# Class is invoked when the app is called via an external message
class window.MessageHandler

  @DIRECTIVE: {
    CONTEXT: 'context',
    USER: 'user',
    NONE: null
  }

  @handle_message: (url) ->
    # alert("Called MessageHandler with url #{url}")
    Logger.log("MessageHandler url="+url);
    UserHandler.safe_fetch_models()
    @handle_launch_directive(@get_launch_directive_from_url(url))
    # context_id = @get_url_param(url,'c');
    # if ( context_id )
    #   if ( parseInt(context_id) ) then @handle_context(context_id) else UserHandler.startup({unknown_user:true})
    # else if ( user_id = @get_url_param(url,'u') ) 
    #   @handleUser(user_id)
    # else 
    #   UserHandler.startup({fresh:@get_url_param(url,'fresh')})

  # Get the launch directive based upon 
  @get_launch_directive_from_url: (url) ->
    if (  context_id = @get_url_param(url,'c'))
      if parseInt(context_id) then {type: @DIRECTIVE.CONTEXT, id: context_id} else {type: @DIRECTIVE.USER, id: "new"}
    else if ( user_id = parseInt(@get_url_param(url,'u')) ) 
      {type: @DIRECTIVE.USER, id: user_id}
    else 
      {type: @DIRECTIVE.NONE, id: @get_url_param(url,'fresh')}

  # Process the launch directive
  @handle_launch_directive: (directive={}) ->
    Logger.log("MessageHandler handling directive "+JSON.stringify(directive))
    switch directive.type
      when @DIRECTIVE.CONTEXT then  @handle_context(directive.id)
      when @DIRECTIVE.USER 
        if parseInt(directive.id) then  UserHandler.set_user(directive.id) else UserHandler.startup({unknown_user:true})
      else UserHandler.startup({fresh:directive.id})
    

  @handle_context: (context_id) ->
    ViewController.auto_render(false)

    $.ajax({
      url: Config.base_url()+"/get_context/"+context_id, 
      dataType: "json",
      async: false,
      data: {v: Config.version}
      # Note that we currently only support a single context which has user_id and occasion_id, that is, it's for invites
      # but we should be able to support other contexts such as photo-tagging, in which case we would 
      # change the page to the correct gallery
      success: (context) ->
        Logger.log("MessageHandler received context type "+ context.type)
        # We set a current occasion even if the Occasions is empty
        if context.occasion  
          set_current_occasion(new Occasion context.occasion)
          current_occasion().prepare_for_display()
        
        if context.photo and Occasion.find context.photo.occasion_id 
          set_current_occasion Occasion.find context.photo.occasion_id 
          
        if (context.type == "Invite" )
          # GARF - This is super-easy to spoof.  Someone just has to create a message w/ some invite and they get to 
          # register as someone else.... 
          # Also, we haven't necessarily checked in yet, so not sure that we have a current user
          set_current_user(context.user)
          Occasion.load_from_server(UserHandler.go_home)
        else if context.type == "Occasion"
          GalleryController2.show(current_occasion())
        else if context.type == "Comment" || context.type == "Photo" || context.type == "Like"
          # When the photo is loaded, we also load its current occasion
          Photo.add(context.photo).load_from_server((photo) -> 
            # Carousel.display_photo(photo)
            # SANI - Not sure what we should be doing here - right now I'm just displaying the gallery
            # but we need to go to the right photo and display the comments 
            photo.occasion().load_from_server(-> GalleryController2.show_new_content(photo.occasion())) 
          )
        else if ( context.type == "PhotoTagging")
            # TODO - Show the user the photo that was tagged - he's already automatically subscribed to the occasion
          Logger.log("received context Phototagging")
          set_current_user(context.user);
        else 
          Logger.error("MessageHandler unknown context type"+context.type)
          UserHandler.go_home()

      error: (jqXHR, textStatus, errorThrown) ->
        Logger.error("MessageHandler getting context info for context id #{context_id}");
    })
        
  # Here's a function to get the url parameters.  Call it with the parameter name
  # and it'll return the value or null
  @get_url_param: (url,name) ->
    results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(url);
    return (results && results[1]) || null
