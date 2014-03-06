class Footsteps
    
  # This class is used to keep track of user activity on the site, mainly to support cancellations and back buttons, but it could
  # be used in a more general purpose manner.  In its intended use, we want to automate the handling of "back" buttons and cancellations
  # in wizards, and where you might want to jump to a login or registration page prior to coming back to the main page
  # Examples include:
  #   You're looking at a particular record, and want to comment, but the system requires you to login.  You login, either via a
  #   Ajax form, in which case you remain on the page, or via a separate form, in which case you want to go back to the page you 
  #   were on.  
  #   If this is what you're using this class for, then you probably also want to reset the history on pages that don't have forms, such
  #   as the landing page or a news page.  In this case, you make the footstep stack small, and you specify that you only want
  #   to keep certain pages. 
  # Elaboration
  #   We get requests in one of three modes: get, post, and xml post (i.e. Ajax).  Get's and Posts are generally easy to deal with
  #   We save the location as needed, and then return.  Since Rails doesn't have the equivalent of a forward, each of these is 
  #   presumably a render option (although technically, we don't really care - we just return the cached request)
  #   An Ajax request expects to get the response back as in the background, with some javascript possibly interpreting that response.  
  #   If we have a scenario where the response is a redirect, then the context for the Ajax call is lost, and after fulfilling the 
  #   request it's hard to go back to that, short of coming up with some protocol between the client and server, which directs the 
  #   client to go to the previous page and reissue the Ajax request.


  # This class keeps the information regarding a request so that we can go back to it
  #
  # class Step    
  #   def initialize(request)
  #     @info = { 
  #               :method => request.method,
  #               :uri => requeset.url,
  #               :params => request.parameters
  #               }
  #     # @request = request
  #   end
  #   
  #   def get?
  #     @info[:method] == :get
  #   end
  #   
  #   def method
  #     @info[:method]      
  #   end
  #   
  #   def uri
  #     @info[:url]
  #   end
  #   
  #   def params
  #     @info[:param]
  #   end
  # end
  
  class Log
    
    @@logger = nil
    @@log_level = nil
    
    def self.logger
      @@logger
    end
    
    def self.init(logger, level)
      @@logger = logger
      @@log_level = level
    end
    
    def self.debug(*args)
      @@logger.debug(*args) if @@logger && ![:info,:warn].include?(@@log_level) 
    end
    
    def self.info(*args)
      @@logger.info(*args) if @@logger && @@log_level != :warn
    end
    
    def self.warn(*args)
      @@logger.warn(*args) if @@logger
    end
    
  end
  
  # Class initializer
  # You call this to initialize the handling of the footstep manager system-wide
  # Primarily we initialize the system and define what locations need to be kept,
  #   :save => locations that should be kept for return (if set blank, then all not otherwise explicitly ignored will be)
  #   :ignore => locations to ignore and not save - typically, we don't save pages with individual forms on them unless
  #              they're in a wizard or we want to be able to go back to them  (i.e. intercept via login, then go back)
  #   :reset  => locations that reset the stack ... that is, after certain locations going "back" may not make sense, for example,
  #             the site or controller index pages
  #   :depth  => number of footsteps to track.  Default max is 5
  #   :logger => Initialize the logger object to be used
  #   :cancel => indicate the regexp that indicates what a cancel is
  # Warning: In case of logic conflicts, the following priority is applied: ignore, track, reset
  def self.init (config={})
    @@save = config[:save] || []
    @@reset = config[:reset] || []
    @@ignore = config[:ignore] || []
    @@depth = config[:depth] || 5
    @@default = config[:default] || :save
    @@cancel = config[:cancel].is_a?(Regexp) ? config[:cancel] : /cancel/i
    logger = config[:logger] || Rails.logger
    Log.init(logger, config[:log_level]|| :info)
  end
  
  def cancel?(request)
    request.post? && @@cancel.match(request.request_parameters['commit'])
  end
  
  def initialize ()
    reset
    @last_page = {}
  end

  # To be called when a new request comes in, so that the decision can be made as to whether to 
  # track this footstep or not
  #   Inputs:
  #     request 
  # Returns
  #   boolean indicating if footstep was tracked
  def track(request)
    # If the user has just reloaded the page, don't bother saving it
    tracked = false
    if ( request.get? && !request.xhr? )
      save_current(request)
      if ( @footsteps.size > 0 && @footsteps.last[:uri] == request.url ) 
        Log.info("Not tracking #{request.url} b/c it matches last saved location [#{@footsteps.size}]") 
      elsif ( check_match(@@save,request) )
        Log.info("Saving #{request.url} b/c of save list match [#{@footsteps.size}]") 
        tracked = save_footstep(request)
      elsif ( check_match(@@ignore,request) )
        Log.info("Not tracking #{request.url} b/c of ignore list match [#{@footsteps.size}]") 
      elsif ( check_match(@@reset,request) )
        Log.info("Resetting list #{request.url} b/c of reset list match [#{@footsteps.size}]") 
        reset
        tracked = save_footstep(request)
      else
        case @@default
        when :reset
          reset
          tracked=save_footstep(request)
          Log.info("Reset and save #{request.url} b/c of default action [#{@footsteps.size}]") 
        when :save
          tracked=save_footstep(request)
          Log.info("Saving #{request.url} b/c of default action [#{@footsteps.size}]") 
        end
      end
    else
      # Don't save anything for xml requests or posts right now
      # Later we will implement the capability to cache an xml post request, switch to 
      # a login controller, and then go back and handle the post itself, in which case we do need
      # to track xml footsteps....
    end
    tracked
  end

  # return the last footstep and remove it from the list we track
  # the current location is passed via the request object - this method checks the current request URI vs
  # what was saved and skips it if it matches
  def step_back(request)
    # We're intentionally popping two off the stack... The assumption is that the current page was
    # arrive at via some "get" operation that has been cached, so by popping two, we are
    # in fact going back to the one before this one
    @footsteps.pop if (  @footsteps.last && @last_page[:uri] == @footsteps.last[:uri])
    val = @footsteps.pop
    Log.info "Popping off from the stack: #{val.inspect} - current: #{request.url}" 
    # If we are passed a request object, we check to make sure that we do not just go back to the same
    # place we cancelled out of
    if !request.nil? 
      while (val && val[:uri] && val[:uri] == request.url ) 
        val=@footsteps.pop
        Log.info "Continue popping off from the stack b/c it matches request: #{val.inspect} [#{@footsteps.size}]" 
      end
    end
    val
  end
  
  # This returns the previous page that was arrived at via a get operation
  def previous_page(request)
    index = -1
    index -=1 if @footsteps.last && @last_page[:uri] == @footsteps.last[:uri]
    val = @footsteps[index]
    if !request.nil?
      while (val && val[:uri] && val[:uri] == request.url ) 
        index -= 1
        val = @footsteps[index]
      end
    end
    val
  end
  
  attr_reader :last_page
    
  def inspect
    x =<<-END
Last Page: #{@last_page[:uri]}
Footsteps:
    END
    y = []
    @footsteps.reverse.each_with_index { |step,i| 
      y << "#{i}: #{step[:uri]}"
    }
    x + y.join("\n").shift_right(2)
  end
  
  def reset
    @footsteps = []
  end

  private

  # We always save the top-most page separately
  # even if it's not saved on the footsteps
  # NOTE: we dup the parameters in case some step in the request processing over-writes them
  def save_current(request)
    @last_page = { 
      :method => request.method,
      :uri => request.url.dup,
      :params => request.parameters.dup
    }
    Log.debug("Set current page to #{request.url}")
  end
  
  # Save the footstep so that we can retrieve it later 
  # for now only save get requests but this will likely have to be updated in the future
  def save_footstep(request) 
    if ( request.get? && (@footsteps.size == 0 || @footsteps.last[:uri] != request.url) ) 
      @footsteps.push( { 
                :method => request.method,
                :uri => request.url.dup,
                :params => request.parameters.dup
                } ) 
      # In case we have a leak, we want to limit the memory growth, so just limit saved contexts
      Log.info "Saved footstep with URI(#{request.url}) XML: #{request.xhr?} [#{@footsteps.size}]" 
      if @footsteps.size >= @@depth 
        @footsteps.shift 
        Log.debug "Had to trim context stack" 
      end
    end
  end
    
  def check_match(list,request)
    # Check if we should even be tracking this...
    return nil if list.nil?
    Log.debug("Footsteps: Checking new request <#{request.url}> against match list")
    list.each do |loc|
      match = true
      next if loc.nil?
      Log.debug("  checking match list entry #{loc.inspect}") 
      loc.keys.each do |key|
        # Log.debug("    Testing <#{key}>")           
        if ( (loc[key].is_a?(String) && loc[key].casecmp(request.parameters[key.to_s]) == 0) ||
             (loc[key].is_a?(Regexp) && loc[key].match(request.parameters[key.to_s]) ) )
          Log.debug("    <#{key}> MATCHED, #{loc[key]} vs #{request.parameters[key.to_s]}  testing next key") 
        else
          Log.debug("    <#{key}> did not match, #{loc[key]} vs #{request.parameters[key.to_s]} continuing...") 
          match = false
          break
        end
      end
      Log.debug("  match list entry #{loc.inspect} match=#{match}") 
      return true if match
    end
    return nil
  end
    
end

module FootstepControllerMethods
  # ===================================================================
  # = Manage user footsteps so we can cancel out of forms and go back =
  # ===================================================================
  # YOu can do two things:
  #  You can initialize the footsteps based upon some parameters described above
  #  You must add an append_before_filter for manage_footsteps so that ancellations are automatically handled
  # Footsteps.init(config(:footsteps))
  # ActionController::Base.append_before_filter :manage_footsteps 
  # When called, we can check if the user is cancelling, and if so, 
  # we go back to the previous location.  If not, we see if we need
  # to track this footstep (actually footsteps has the logic for 
  # determining if we need to track it)
  def manage_footsteps
    # If session[:footsteps] isn't set, then skip this
    session[:footsteps] ||= Footsteps.new
    if ( session[:footsteps] )
      if ( session[:footsteps].cancel?(request) )
        logger.my_debug('>'*10,"Cancellation requested intercepted")
        return_to_previous_location
      else 
        session[:footsteps].track(request)
      end
    end
    # We need to make sure that we don't return false b/c filter chain will break
    true
  end
  
  # The previous location 
  # GARF: SANI: I think this should use previous_page rather than step_back as step_back pops off the stack and corrupts the footsteps
  # each time it is called. I was afraid to change it in case it breaks one of our other apps. So I added the method below previous_page.
  def previous_location
    session[:footsteps].step_back(request)    
  end
  
  # The previous page 
  # See the above comment for previous_location.
  def previous_page
    session[:footsteps].previous_page(request)    
  end
  
  
  # If for some reason we need to return to the previous location, we take
  # it back from the footsteps
  def return_to_previous_location(message = nil)
    # Pass request to the footsteps so that it doesn't come back to the same
    # spot
    last = session[:footsteps].step_back(request)
    logger.debug("Redirecting user to #{last.inspect}")
    if ( request.xhr? )
      # Handle ajax differently
      logger.my_debug('Redirecting back to previous location for ajax')
      render :json =>  AjaxResponse.new.redirect_to( last ? last[:uri] : '/',message) 
    else 
      flash[:notice] = message if message
      last ? redirect_to(last[:uri]) : redirect_to_index
    end
  end
  
  def return_to_same_location(message = nil)
    last = session[:footsteps].last_page[:uri]
    logger.my_debug('<'*15,"Returning to #{last}")
    if ( request.xhr? )
      # Handle ajax differently
      render :json =>  AjaxResponse.new.reload_page(message) 
    else 
      flash[:notice] = message if message
      last ? redirect_to(last) : redirect_to_index
    end
  end
  
  def current_location
    session[:footsteps].last_page[:uri]
  end
  
end
