# Seed the database with dummy data to be used in our basic playing around testing so we have at least one 
# party for testing

puts "Loading dummy data (notifications disabled!)"
Notification.enable!

if User.find_by_mobile_number("1112223333")
  puts "User mark spencer already exists"
else
  puts "Loading user mark spencer"
  mark = User.create!({:first_name => "Mark", :last_name => "Spencer", :mobile_number => "1112223333", :status => :active,
        :sourced_contacts_attributes => [{:first_name => "Sarah", :last_name => "Barnes", 
        :contact_details_attributes => [{field_name: "mobile", field_value: "2223334444"}] 
      }]
    })

  occasion = Occasion.create!({:name => "Muriel's Wedding", :user => mark})  
  Invite.create!(:inviter => mark, :invitee => mark.sourced_contacts.first.user, :occasion  => occasion)
end

# Now create a much larger pool of users, who we can then connect to each other 
FAKE_USER_COUNT = 20

userPool = []
FAKE_USER_COUNT.times do 
  userPool << {:first_name => Faker::Name.first_name, 
    :last_name => Faker::Name.last_name, 
    :email => Faker::Internet.email, 
    :mobile_number => Faker::PhoneNumber.cell_phone,
    :home_number  => Faker::PhoneNumber.phone_number
   }
end


if User.count >= FAKE_USER_COUNT
  puts "Users & contacts: skipping"
else
  # Now we have fake users, so let's go ahead and make contact records between them, if none currently exist
  # the contact records have to have the following permutations
  # Give each btween 2 and 5 contacts
  puts "Users & contacts: CREATING..."
  userPool.each do  |user_info|
    contacts_length = [2,3,4,5].sample
    user = User.find_or_create!(user_info.except(:home_number).merge({:status => :active}))
    puts "  Creating contact list for #{user.log_info}"
    used = []
    while user.sourced_contacts.count < contacts_length do
      cr = userPool.sample
      unless user_info == cr || used.include?(cr)
        crn = ContactRecord.new(first_name: cr[:first_name], last_name: cr[:last_name])
        # At random assign some contact details here - not all, but some, just to see that the system behaves ok
        r = rand(4)
        if r >= 1 then crn.contact_details << ContactDetail.new(field_name: "mobile", field_value: cr[:mobile_number]); end
        if r < 2 then crn.contact_details << ContactDetail.new(field_name: "home", field_value: cr[:home_number]); end
        if r >= 2 then crn.contact_details << ContactDetail.new(field_name: "email", field_value: cr[:email]); end
        user.sourced_contacts << crn
        used << cr
        puts "  Created contact record for #{crn.name} with #{crn.details.count} details"
      end
    end
  end
end

all_users = User.with_sourced_contacts
OCCASION_NAMES = ["Sally's Wedding", "Vegas Trip", "Aussie Floyd Concert", "Priory Auction", "4th Grade WES Camping Trip"]
if Occasion.count(:conditions => "latitude IS NOT NULL") < OCCASION_NAMES.length
  puts "Occasions: CREATING...."
  OCCASION_NAMES.each_with_index do |name, i|
    Occasion.create!({:name => name, :start_time => i.days.ago, :user_id => all_users.sample.id}.merge(Geolocation.sample.to_hash))
    puts "  Created occasion #{name}"
  end
else
  puts "Occasions: skipping"
end


occasions = Occasion.all

# These are rough numbers 
INVITERS_COUNT = 4
if Invite.count < 10
  # Now go ahead and create some invitations, choose a few users and create invitations
  puts "Invites: CREATING...." + "(invites from #{INVITERS_COUNT} users)"
  inviters = all_users.sample(INVITERS_COUNT)
  inviters.each do |inviter|
    inviter.sourced_contacts.sample(1+rand(3)).each do |invitee_contact|
      puts invitee_contact.inspect
      invite = inviter.invite(invitee_contact.user,occasions.sample)    
      puts "  #{inviter.hs} invited #{invitee_contact.user.hs} to #{invite.occasion.hs}"
    end
  end
else
  puts "Invites: skipping"
end


# Now create the photos based upon what we have
if Photo.count < Occasion.count
  puts "Photos: CREATING...."
  Rake::Task["photos:import"].execute
  puts "  Added #{Photo.count} photos"
  
  Photo.all.each do |photo|
    photo.user_id = all_users.sample.id
    photo.occasion_id = occasions.sample.id
    photo.save!
    photo.create_participation_event
    puts "  Added user and occasion info to photo #{photo.id}"
  end
else
  puts "Photos: skipping"
end

# Make sure each occasion has at least on photo
puts "Adding at least one photo for each occasion"
raise "You must have more photos than occasions in your seed data" if Photo.count < Occasion.count
Occasion.all.each_with_index do |occ, i|
  photo = Photo.all[i]
  photo.user_id = all_users.sample.id
  photo.occasion_id = occ.id
  photo.save!
  photo.create_participation_event
  puts "  Added at least one photo to occasion #{occ.id}"
end


# Now create the photo taggings
TAGGED_PHOTO_PERCENT = 30
if PhotoTagging.count < 10
  puts "PhotoTagging: CREATING...." + "(phototaggings for #{TAGGED_PHOTO_PERCENT}% of photos"
  # roughly tag half the photos
  Photo.all.sample((Photo.count * TAGGED_PHOTO_PERCENT)/100).each do |photo|
    tagging = all_users.sample.tag_photo(photo,all_users.sample)  
    puts "  #{tagging.tagger.log_info} tagged photo #{photo.id} with #{tagging.taggee.hs}"
  end
else
  puts "PhotoTagging: skipping"
end
