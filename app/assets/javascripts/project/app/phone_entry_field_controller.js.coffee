# No longer works with JQM only with Pager
class window.PhoneEntryFieldController
  
  constructor: (pef_id) ->
    PhoneEntryFieldController.instances ||= {}
    PhoneEntryFieldController.instances[pef_id] = @ 
    
    @pef_id = pef_id
      
    @setup_click_handlers()
  
  # =================
  # = Class Methods =
  # =================
  @country_selected: (el) =>
    pef_id = $("#country_code_list").data("pef_id")
    iso = $(el).data("iso")
    code = $(el).data("code")
    country = $(el).data("country")
    PhoneEntryFieldController.instances and PhoneEntryFieldController.instances["#{pef_id}"].country_selected(iso, code, country)
    
  
  # ====================
  # = Instance Methods =
  # ====================
  setup_click_handlers: => 
    $(@cc_button()).off "click"
    $(@cc_button()).on "click", @cc_button_click
  
  cc_button: => $("##{@pef_id} .npb-country-code-button")
  
  cc_button_click: => 
    $("#country_code_list").data("pef_id", "#{@pef_id}")
    Pager.change_page("country_code_list")
  
  country_selected: (iso, code, country) =>
    @update_button(iso)
    @update_text_field(code)
    Pager.back()
  
  update_button: (iso) => $("##{@pef_id} .ui-btn-text").removeClass().addClass("ui-btn-text flag #{iso}")
  
  update_text_field: (code) => $("##{@pef_id} .npb-phone-w-country-text-input").val("+(#{code}) ").focus()