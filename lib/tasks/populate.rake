namespace :db do
  desc "Populate users in db for testing purposes"
  task :populate => :environment do
    require 'populator'
    require 'faker'
    
    [User, ContactDetail].each(&:delete_all)
    
    #  Fill the users and contact details with a variety of possibilities for number of emails, number of non-sms phones, and number of sms phones
    user_types = [
  #Emails    #NonSMS ph   #SMS ph
    [2,           2,          0],
    [1,           2,          0],
    [0,           2,          0],

    [2,           1,          1],
    [1,           1,          1],
    [0,           1,          1],

    [2,           0,          0],
    [1,           0,          0],
    [0,           0,          0],

    [2,           1,          0],
    [1,           1,          0],
    [0,           1,          0],

    [2,           0,          1],
    [1,           0,          1],
    [0,           0,          1],

    [2,           0,          2],
    [1,           0,          2],
    [0,           0,          2],
      
    ]
    user_types.each_with_index do |ut, u_index|
      user = User.create(:first_name => "user_#{u_index}", :last_name => "#{ut[0]}email_#{ut[1]}nonsms_#{ut[2]}sms")
      ut[0].times do # Emails
        ContactDetail.create(:user_id => user.id, :kind => :email, :email => Faker::Internet.email)
      end
      ut[1].times do |i| # NonSMS phone
        ContactDetail.create(:user_id => user.id, :kind => :unknown_phone, :phone => "1#{u_index}#{i}".to_i)
      end
      ut[2].times do |i| # NonSMS phone
        ContactDetail.create(:user_id => user.id, :kind => :unknown_phone, :phone => "2#{u_index}#{i}".to_i)
      end
    end
    
    # User.populate 20 do |category|
    #   category.name = Populator.words(1..3).titleize
    #   Product.populate 10..100 do |product|
    #     product.category_id = category.id
    #     product.name = Populator.words(1..5).titleize
    #     product.description = Populator.sentences(2..10)
    #     product.price = [4.99, 19.95, 100]
    #     product.created_at = 2.years.ago..Time.now
    #   end
    # end
  end
  
  task :add_likes => :environment do
    Photo.all.each do |p|
      ( User.all.randomize.first (rand*10).round ).each do |u|
        Like.create(:user_id => u.id, :photo_id => p.id)
        puts "#{p.id} #{u.id}"
      end
    end
  end
  
  task :add_captions => :environment do
    Photo.all.each{|p| p.update_caption Faker::Lorem.sentence(3)}
  end
  
  task :add_comments => :environment do
    Comment.destroy_all
    Photo.all.each do |p|
      3.times{|i| random_new_comment(p).save}
    end
  end
  
  def random_new_comment(photo)
    Comment.new :user_id => User.all.randomize.first.id, :photo_id => photo.id, :body => Faker::Lorem.sentence(30)
  end
  
end
