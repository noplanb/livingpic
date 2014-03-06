require 'test_helper'

class ParticipationTest < ActiveSupport::TestCase

  require 'participation'

  setup do 
    @user = User.create!( { :first_name => "Sally", :last_name => "may", :status => :active, :sourced_contacts_attributes =>  
      [
        { :first_name => "john",:last_name => 'doe', :contact_details_attributes => [
          { :field_name => "mobile", :field_value => "+12123334444"},
          { :field_name => "home", :field_value => "213-555-1999"},
          { :field_name => "home", :field_value => "a@home.com"},
          { :field_name => "work", :field_value => "b@work.com"},
        ]}
      ]
    })
    
    @occasion = Occasion.create!(:name => "Party!",:user_id => @user.id)
    @user2 = User.where(:first_name => 'John', :last_name => "Doe").first
    @invite = Invite.create!(:occasion => @occasion, :inviter => @user, :invitee => @user2)

    # For occasion 2 user 2 is the inviter.  Now each user has 2 occasions they are associated with
    @occasion2 = Occasion.create!(:name => "Graduation!",:user_id => @user2.id)
    @invite = Invite.create!(:occasion => @occasion, :inviter => @user2, :invitee => @user)

  end

  test "creates only one participation record per user, kind, and occasion" do
    assert_equal(3, Participation.count)
    participations = Participation.all
    # This shouldn't create a new participation event
    a = Participation.find_or_create!(:user_id => @user.id,:occasion_id => @occasion.id, :indication => @invite)
    assert_equal(3, Participation.count)
    assert participations.include? a
  end

  test "we should receive multiple participation occasions" do
    assert_equal(2, Participation.prioritized_occasions_for_user(@user).length)
      
  end
end
