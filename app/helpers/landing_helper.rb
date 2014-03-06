module LandingHelper
  
  def personal_message(social_action)
    text = case social_action
    when :tag; "I saw a nice photo of you at"
    when :invite; "I thought you'ld like to see the pics of"
    when :like; "I just liked a photo of you at"
    when :comment; "I just commented on a photo of you at"
    when :threshold; "The 100th photo has just been snapped at"
    when :participation; %~#{linkified_participants} #{other_participants} #{@participation.relevant_participants.length > 1 ? 'have' : 'has'} just started snapping #{linkify_for_participation("Living Pics")} of~
    end
    text.html_safe
  end
  
  def linkified_participants
    @participation.relevant_participants.map{|p| linkify_for_participation(p.fullname)}.to_sentence
  end
  
  def linkify_for_participation(text)
    %~<a href='#get_the_app_participation' data-rel='dialog' data-transition='flip'>#{text}</a>~
  end
  
  def other_participants
    num_other = @participation.num_participants - @participation.relevant_participants.length
    if num_other > 1
      "and " + linkify_for_participation("#{num_other} others")
    else
      nil
    end
  end
  
  def app_reviews
    [
      Hashie::Mash.new({:title => "Brilliant!", :author => "Jay Prescott", :description => "I love this app. It works seemlessly when we are several people taking pics at an occasion. Whenever I am at a group event like a wedding I just start using LivingPic and magically we can all see the photos taken by everyone there.".html_safe}),
      Hashie::Mash.new({:title => "Love it!", :author => "Lucy Rainbow", :description => "What a great app. I really like how you can see everyone else's pics at an event. It beats the heck out of cajoling everyone to share their pics in an album afterwards."}),
      Hashie::Mash.new({:title => "Works like a charm", :author => "Jeremy Walker", :description => "#{site_name} is awesome! What a great idea. My favorite part is how it organizes all my pics by the occasions I was at. And it shows me pics that others took there as well."})
    ]
  end
  
  def call_to_action_text(type)
    text = case type
    when :participation; "<h3>See pics by #{@participation.relevant_participants.map{|p| p.first_li}.to_sentence} of #{@notification.occasion.name}!</h3>"
    when :enlarge; "<h3>See fullsize pics of #{@notification.occasion.name}</h3>"
    else; "<h3>See all pics of #{@notification.occasion.name}!</h3>"
    end
    text.html_safe
  end
  
end
