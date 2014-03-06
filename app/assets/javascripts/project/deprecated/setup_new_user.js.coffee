# Deprecate when FtuiController.submit_new_user_name is working. 

$(document).ready ->
  $("#unknown_user").on "pageshow", -> 
    new PhoneEntryFieldController("unknown_user_phone")
  
window.submit_new_user_name = (form_data) -> 
  user = array_to_hash(trim_all_form_data(form_data))
  user.mobile_number = user.mobile_number.trim_phone()
  if user.first_name is ""
    alert("Please enter your first name") 
    return
  
  if user.last_name is ""
    alert("Please enter your last name")  
    return
  
  unless user.mobile_number.is_phone()
    alert("Please select country and enter your mobile number with area code.")  
    return

  set_current_user(user)
  confirmed_name()  
