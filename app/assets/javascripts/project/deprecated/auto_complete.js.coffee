# ================
# = AutoComplete =
# ================
class window.AutoComplete

  constructor: (options={}) -> 
    # These must be specified
    @page_id = null
    @full_list = null

    # These are optional
    @fill_input_with_pick = false
    @theme = null
    @template_for_list_item = null
    @template_for_picked_item = null
    @dont_use_first_letter_list = false
    @show_all_on_first_letter = false
    
    AutoComplete.INSTANCE = @
    console.log "Creating new autoComplete"
    unless options.page_id? 
      $.error "AutoComplete requires a page_id. This should be the id of the page containing the autocomple view elements."
    @page_id = options.page_id
    
    unless options.full_list?
      $.error "AutoComplete requires 'options.full_list. Which should be array of the form: id: integer, str: String"
    @full_list = options.full_list
    
    @theme = if options.theme? then options.theme else "c"
    @dont_use_first_letter_list = options.dont_use_first_letter_list if options.dont_use_first_letter_list?
    @show_all_on_first_letter = options.show_all_on_first_letter if options.show_all_on_first_letter?
    
    # Note by convention the html must contain the following class names under a page with id="page_id"
    search_input_field = $("##{@page_id} .auto_complete_search_input_field")
    search_input_field.val ""
    search_results_box = $("##{@page_id} .auto_complete_search_results_box") 
    picked_items_box = $("##{@page_id} .auto_complete_picked_items_box")
    
    @fill_input_with_pick = options.fill_input_with_pick? && options.fill_input_with_pick
    
    @template_for_list_item =  if options.template_for_list_item? then options.template_for_list_item else  "<li data-auto_complete_id='list_item_id'
                                                                                                                 data-auto_complete_str='escaped_str' 
                                                                                                                 class='ui-btn ui-btn-icon-right ui-li-has-arrow ui-li ui-btn-up-#{@theme}'
                                                                                                                 onclick='list_item_pick_onclick_text' >
                                                                                                              <div class='ui-btn-inner ui-li'>
                                                                                                                <div class='ui-btn-text'>
                                                                                                                  <a class='ui-link-inherit' href='#'>list_item_str</a>
                                                                                                                </div>
                                                                                                                <span class='ui-icon ui-icon-plus ui-icon-shadow'> </span>
                                                                                                              </div>
                                                                                                            </li>"
    
    @template_for_picked_item = if options.template_for_picked_item? then options.template_for_picked_item else   "<a class='ui-btn ui-btn-inline ui-shadow ui-btn-corner-all ui-mini ui-btn-icon-right ui-btn-up-#{@theme}' 
                                                                                                                      data-auto_complete_id=''
                                                                                                                      onclick='AutoComplete.INSTANCE.acp.delete(this)'>
                                                                                                                      <span class='ui-btn-inner ui-btn-corner-all'>
                                                                                                                        <span class='ui-btn-text'>Some text</span>
                                                                                                                        <span class='ui-icon ui-icon-delete ui-icon-shadow'> </span>
                                                                                                                      </span>
                                                                                                                    </a>"   
    @acd = new AutoCompleteDisplay( page_id: @page_id )
    @acp = new AutoCompletePick( page_id: @page_id, fill_input_with_pick: @fill_input_with_pick, picked_items_box: picked_items_box, template_for_picked_item: @template_for_picked_item, on_delete: @acd.on_delete, on_pick: @acd.on_pick )
    @acs = new AutoCompleteSearch( full_list: @full_list, search_input_field: search_input_field, search_results_box: search_results_box, pick_onclick_text: "AutoComplete.INSTANCE.acp.pick(this)", on_auto_complete: @acd.on_auto_complete, template_for_list_item: @template_for_list_item, dont_use_first_letter_list: @dont_use_first_letter_list, show_all_on_first_letter: @show_all_on_first_letter )
    
  picked_items: => @acp.picked_items
  picked_ids: => keys(@picked_items())
  picked_item_names: => @picked_ids().map (id) => @picked_items()[id]
  has_picked: => @picked_ids().length > 0
  none_picked: => not @has_picked()
    
  @dispose: =>
    @acd = null
    @acp = null
    @acs = null
    AutoComplete.INSTANCE = null
  
# ======================
# = AutoCompleteSearch =
# ======================
# NOTE: This should not be instantiated. It is instantiate by the parent AutoComplete above.
# 
# Takes a list element is {id: id, str: full_string_to_be_matched} e.g. the contact list
# when you perform check(fragment) it returns a subset of the list which matches fragment
# 
# If the fragment is 1 letter it matches only against the first letter. If it is more than one letter
# then it matches against anywhere in full_string_to_be_matched.
# 
# AutoComplete retains a history of searches and uses them rather than perfomring a new search
# AutoComplete tries to search agaisnt the results of a previous search rather than the full list if it knows 
# that the are a superset of the results of this search.
#  
# Use as follows
# ac = new AutoComplete     or    ac = new AutoComplete({full_list: array})
# then call ac.check(fragment) for each word fragment you want to check the list against.
class window.AutoCompleteSearch

  # options.full_list :: an array where each element is {id: id, str: full_string_to_be_matched} e.g. the contact list
  constructor: (options={}) ->   
     
    # These must be specified
    @search_input_field = null
    @search_results_box = null
    @pick_onclick_text = null
    @template_for_list_item = null
    
    #  These are optional
    @on_auto_complete = ->
    @dont_use_first_letter_list = false
    @show_all_on_first_letter = false
    @max_show_all = 50
    
    # These are internal attributes
    @full_list = []
    @previous_matches = {}
    @first_letter_list = {}
    @first_letter_return_max_list_size = 50
    
    unless options.search_input_field?
     $.error "AutoCompleteSearch requires 'options.search_input_field' for which is monitored for text input. E.g. ac = new AutoCompleteSearch(search_input_field: $('#invite .auto_complete_exp' ))" 
    @search_input_field = options.search_input_field
    
    unless options.search_results_box?
      $.error "AutoCompleteSearch requires 'options.search_results_box' for which is monitored for text input. E.g. ac = new AutoCompleteSearch(search_results_box: $('#invite .auto_complete_search_results_box' ))" 
    @search_results_box = options.search_results_box
    
    unless options.pick_onclick_text?
      $.error "AutoCompleteSearch requires 'options.pick_onclick_text'." 
    @pick_onclick_text = options.pick_onclick_text
    
    unless options.template_for_list_item?
      $.error "AutoCompleteSearch requires 'template_for_list_item"
    @template_for_list_item = options.template_for_list_item 
    
    @on_auto_complete = options.on_auto_complete if options.on_auto_complete?
    
    unless options.full_list? 
      $.error "AutoCompleteSearch requires 'options.full_list'"
    @full_list = options.full_list 
    
    @dont_use_first_letter_list = options.dont_use_first_letter_list if options.dont_use_first_letter_list?
    @show_all_on_first_letter = options.show_all_on_first_letter if options.show_all_on_first_letter?
    @setup_first_letter_list()
    @setup_event_listner_on_search_input() 
        
  setup_event_listner_on_search_input: =>    
    @search_input_field.bind "keyup", (event) =>  
      # Fill the AutoComplete list with the search results
      exp = @search_input_field.val()
      @search_results_box.html(@check exp)
      @on_auto_complete()
    
  
  # Used for speedy return of single letter searches (note we match on first letter for these)
  setup_first_letter_list: =>
    @first_letter_list = {}
    for item in @full_list
      do => 
        fl = item.str[0].toLowerCase()
        @first_letter_list[fl] = [] unless @first_letter_list[fl]?
        @first_letter_list[fl].push item unless @first_letter_list[fl].length >= @first_letter_return_max_list_size
  
  get_first_letter_list_for: (exp) =>
    return [] unless exp.length is 1 
    r = @first_letter_list[exp.toLowerCase()]
    return if r? then r else []
        
  match: (exp, str) => 
    return false unless typeof(exp) is "string" and typeof(str) is "string"
    
    patt = if exp.length is 1 then new RegExp("^#{exp}", "i") else new RegExp(exp, "i")
    return patt.test(str)
    
  check: (exp) =>
    return "" unless typeof(exp) is "string" and exp isnt ""
    
    # Return the full_list if that option is desired.
    if exp.length is 1 and @show_all_on_first_letter and @full_list.length <= @max_show_all
      console.log "Showing all"
      return @html_for_list( @full_list )
      
    # return the first letter hash result if it applies
    if exp.length is 1 and not @dont_use_first_letter_list
      console.log "Using first letter hash"
      return @html_for_list( @get_first_letter_list_for exp  )
      
    if @previous_matches[exp]?
      console.log "Found #{exp}: " + @previous_matches[exp].length
      return @html_for_list( @previous_matches[exp] )
    
    # Use a previous matches list rather than the full list if it applies.
    prev_exp = @shortest_list_for_expression(exp)
    list = null
    if prev_exp 
      console.log "Using list: #{prev_exp}"
      list =  @previous_matches[prev_exp]
    else
      console.log "Using full_list"
      list = @full_list
      
    # console.log list.length
       
    @previous_matches[exp] = []
    for row in list 
      do => 
        @previous_matches[exp].push(row) if @match(exp, row.str)
    # console.log(@previous_matches[exp].length)
    return @html_for_list(@previous_matches[exp])

  # If one of the previous_match lists is a superset of the matches that this expresson will have 
  # then return the key to the shortest previous match list which is such a superset
  # i.e. the one with the longest key. 
  # 
  # So find the longest previous expression that is also contained within this expression
  shortest_list_for_expression: (exp) =>
    fits = []
    previous_exps = keys(@previous_matches)
    for p_exp in previous_exps
      do =>
        patt = RegExp(p_exp, "i")
        fits.push(p_exp) if patt.test(exp) # Check to see if the an old pattern fits in the new one.
    if fits.length == 0 
    else   # Find the longest one.
      # Dont use lists with a single letter as the key since they are composed only of words starting with that letter
      # and are not a superset of lists with two letters which match anywhere in the string.
      lw = fits.longest_word()
      return if lw.length == 1 then false else lw 
      
  html_for_item: (item) => 
    return @template_for_list_item.replace(/list_item_id/g, item.id).replace(/escaped_str/, escape item.str).replace(/list_item_str/, item.str).replace(/list_item_pick_onclick_text/g, @pick_onclick_text)
  
  html_for_list: (list) =>
    r = ""
    for item in list
      do =>
        r = r + @html_for_item(item)
    return r

# ====================
# = AutoCompletePick =
# ==================== 
# NOTE: This should not be instantiated. It is instantiate by the parent AutoComplete above.
#   
# This is used to handle picking items from an autoCompletion
# The convention is that the item will be in an li element. 
# The name of the string for the item will be in data("str")
# The id for the item will be in data("id")
class window.AutoCompletePick

    
  constructor: (options={}) ->
    # These must be specified:
    @picked_items_box = null
    @template_for_picked_item = null
    @page_id = null

    # These are optional
    @fill_input_with_pick = false
    @on_delete = ->
    @on_pick = ->

    # These are internal
    @picked_items = {}    # Will be a hash indexed by id of the str of the picked items.

    unless options.picked_items_box?
      $.error "AutoCompletePick requires 'options.picked_items_box' for where picked items will be displayed. E.g. ac = new AutoCompletePick(picked_items_box: $('#invite .picked_items' ))" 
    @picked_items_box = options.picked_items_box
    
    unless options.template_for_picked_item?
      $.error "AutoCompletePick requires a template_for_picked_item"
    @template_for_picked_item = options.template_for_picked_item
    
    unless options.page_id?
      $.error "AutoCompletePick requires a page_id"
    @page_id = options.page_id
    
    @picked_items = {}
    
    @on_pick = options.on_pick if options.on_pick?
    @on_delete = options.on_delete if options.on_delete?
    @fill_input_with_pick = options.fill_input_with_pick
    
    
  pick: (element) => 
    picked_id = $(element).data("auto_complete_id")
    picked_str = unescape $(element).data("auto_complete_str") 
    
    if @fill_input_with_pick
      $("##{@page_id} .auto_complete_search_input_field").val(picked_str)
    else
      $("##{@page_id} .auto_complete_search_input_field").val("")
    
      
    # If it has already been picked don't add it to the picked list again.
    if @picked_items[picked_id]
      @on_pick()
      return
    
    # Add the picked item to our list
    @picked_items[picked_id] = picked_str
    
    # Add the html for the element to the view
    @picked_items_box.append(@template_for_picked_item)
    added_element = @picked_items_box.children().last()
    added_element.data($(element).data())
    added_element.find(".ui-btn-text").html(picked_str)
    console.log "Picked items = "
    console.log @picked_items
    @on_pick()
    
  delete: (element) =>
    deleted_id = $(element).data("auto_complete_id")
    delete @picked_items[deleted_id]
    $(element).remove()
    @on_delete()

# =======================
# = AutoCompleteDisplay =
# =======================
class AutoCompleteDisplay
    
  constructor: (options={}) ->
    @page_id = options.page_id
       
    # Initialize the display
    # Some other initial states
    $("##{@page_id} .auto_complete_search_results_box").hide()
    $("##{@page_id} .picked_items_block").hide()
  
    # Detect if user shows or hides the keyboard. Explicitly hiding is possible on android. So that results expand to take available space.
    $(window).bind "resize", (event) => 
      @set_search_results_height() 
    
  set_search_results_height:  =>
    # Set the height of the AutoComplete scrolling list
    window_h = Math.floor $(window).height() 
    search_h = Math.floor $("##{@page_id} .search_block").height() 
    $("##{@page_id} .auto_complete_search_results_box").css("height", "#{window_h - search_h - 0}px")    
  
  on_auto_complete: =>
    # Let the css know the search has started. 
    @set_search_results_height() 
    $("##{@page_id}").addClass "search_started" 
    $("##{@page_id} .help").slideUp()
    $("##{@page_id} .picked_items_block").hide()
    $("##{@page_id} .auto_complete_search_results_box").show()
  
  on_pick: =>
    $("##{@page_id} .auto_complete_search_results_box").hide()
    $("##{@page_id} .picked_items_block").show()
    $("##{@page_id} .auto_complete_search_input_field").attr("placeholder", "Type another name")
    
  