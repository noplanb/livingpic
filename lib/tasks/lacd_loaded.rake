namespace :lac do
  
  require "phone_handling"
  include PhoneHandling
  
  LAC_OCCASSION_ID = 162
  
  INVITEES = [
    ["Todd", "Emerson", "206-227-6651"],
    ["Paul", "Cole", "206-369-0573"],
    ["Andy", "Jessberger" , "253-279-5030"], 
    ["Tony", "Vujovich", "206-954-8669"], 
    ["Derek", "Glynn", "206-696-3125"], 
    ["Joe", "Creech", "206 962 0401"], 
    ["Bill", "Wymer","206-459-0566"], 
    ["Lon", "Tierney", "206-679-5677"], 
    ["Patrick", "Taylor", "(206) 459-2057"],  
    ["Steve", "Bader",  "206-954-1684"],   
    ["Keil", "Larsen", "206-953-9633"],   
    ["Brent", "Norton", "206-915-7354"],   
    ["Adam", "Clark", "(206)963-6495"],
    ["Jordy", "LePiane", "208.412.4453"], 
    ["David", "Bentley", "206-914-1227"],
    ["Sean", "McGowan", "425-591-3769"],
    ["Darren", "Des Voigne", "206-478-3231"],
    ["Phil", "Caple", "2069534200"],
    ["Brad", "Cook", "208-860-3727"],
    ["Reynold", "Cottle", "206-719-1643"],
    ["Steve", "Weaver", "206-419-4590"],
    ["Kris", "harness", " 206-799-0793"],
    ["Derek", "DesVoigne", " 206-459-2689"],
    ["Oliver", "Culley", " 2022949277"],
  ]
    
  def dont_reset_user_list 
    [
      User[2],
      User[3],
      User[79],
      User[84],
      User[108],
      User[139],
      User[186]
    ]
  end
  
  
  task :show_invitation_notifications => :environment do
    Notification.where(:occasion_id => LAC_OCCASSION_ID).each do |n|
      puts "#{n.recipient.log_info}: #{n.body}"
    end
  end
  
  task :invite_all => :environment do
    occasion = Occasion.find(LAC_OCCASSION_ID)
    INVITEES.each do |invitee|
      if occasion.participants.include?(user_from_invitee(invitee))
        puts "#{invitee[0]} #{invitee[1]} already participating."
      else
        user = invite(invitee, occasion)
        puts "#{user.log_info} just invited."
      end
    end
  end
   
  def invite(invitee, occasion)
    cr = ContactRecord.create_or_update( cr_format_from_fields(invitee) )
    User[3].invite(cr.user, occasion) if cr.user
    cr.user
  end
  
  def user_from_invitee(invitee)
    cd = ContactDetail.where(:kind => :phone).select{|cd| normalize_phone_number(cd.value) == normalize_phone_number(invitee[2])}.first
    cd && cd.user
  end
  
  def cr_format_from_fields(invitee)
    {
      :first_name => invitee[0],
      :last_name => invitee[1],
      :source_id => 3,
      :contact_details_attributes => [{:field_name => "mobile_phone", :field_value => invitee[2]}]
     }
  end
  
  task :powder_fiesta_status => :environment do
    Occasion[45].participants.each do |u|
      puts "#{u.log_info} | Occs: #{occs_for_u(u)}"
    end
  end
  
  task :reset_powder_users => :environment do
    reset_users = Occasion[45].participants - dont_reset_user_list
    reset_users.each do |u|
      u.reset
      puts "Reset: #{u.log_info} | #{u.status} | Occs: #{occs_for_u(u)}"
    end
  end
  
  task :powder_fiesta_dup_users => :environment do
    Occasion[45].participants.each do |u|
      dups = User.where(:last_name => u.last_name) - [u]
      
      unless dups.blank?
        puts "\n\n#{u.log_info} | Occs: #{occs_for_u(u)}"
        puts "Dups:"
      end
      dups.each do |u|
        puts "  #{u.log_info} | Occs: #{occs_for_u(u)}"
      end
    end
  end
  
  task :delete_stub_notifications => :environment do 
    Notification.all.select{|n| n.trigger.blank?}.each do |n| 
      puts "Destroying Notification #{n.log_info}"
      n.destroy
    end
  end

  
  task :invitee_status => :environment do
    INVITEES.each do |i|
      first = i[0]
      last = i[1]
      phone = i[2] 
      
      nus = User.where(:last_name => last)
      cds = ContactDetail.where(:kind => :phone).select{|cd| normalize_phone_number(cd.value) == normalize_phone_number(phone)}
      
      puts "#{first} #{last} #{phone}"
      if !nus.blank?
        puts "By last name:"
        nus.each do |u|
          puts "  #{u.log_info} #{u.mobile_number} | Occs: #{occs_for_u(u)}"
        end
      end
      
      if !cds.blank?
        puts "By contact detail:"
        cds.each do |cd|
          puts "  #{cd.user.log_info} source: #{cd.contact_record.source.log_info} | Occs: #{occs_for_u(cd.user)}"
        end
      end
      
      puts "Not found" if cds.blank? && nus.blank?
      
      puts ""
    end
    
  end
  
  def occs_for_u(user)
    user.occasions.blank? ? "none" : user.occasions.map(&:log_info).join(',')
  end
  

end
