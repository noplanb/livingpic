# Deprecate when add_participants2.js is working.
# Renders the participants partial usually found in the gallery page
class window.ParticipantsView
  
  @BRIEFLY: 50
  
  @render: (occasion) =>     
    @occasion = occasion
    @has_participants = @occasion.has_participants()
    @particpants_list = @occasion.other_participants_first_and_li()
    @num_participants = @occasion.num_participants()
    
    $(".participants .num_people").html "(#{@num_participants})"
    $(".participants .people_txt_long").html @people_txt()
    $(".participants .people_txt_brief").html @people_txt_brief()
    $(".participants .action_txt").html @action_txt()
    
    if @people_txt().length <= @BRIEFLY
      $(".participants .people_txt_long").show()
      $(".participants .people_txt_brief").hide()
    else
      $(".participants .people_txt_long").hide()
      $(".participants .people_txt_brief").show()
  
  @more_people: =>
    $(".participants .people_txt_long").show()
    $(".participants .people_txt_brief").hide()
    
  @people_txt: => 
    if @has_participants
      "You and #{@particpants_list.join(', ')}"
    else
      "Only you"
      
  @people_txt_brief: =>
    long = @people_txt()
    long.briefly(50) + " &nbsp; <span class='pseudo_link'>more</span>"
      
  @action_txt: =>
    if @has_participants
      "Who is missing? Add them!"
    else
      "Who else?"