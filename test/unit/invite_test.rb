require 'test_helper'

class InviteTest < ActiveSupport::TestCase
  
  setup do
    # Create a user - this should create both Sally May and John Doe
    # See contact_record_test.rb for tests associated with this
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
    @invitee = User.where(:first_name => 'John', :last_name => "Doe").first
  end
  
  test "setup" do
    assert_equal(2, User.count)
    assert_not_nil @invitee, "Contact was not created as user"
  end

  test "raises errors if all fields not complete"  do
    inv = Invite.create(:invitee_id => @invitee.id, :occasion_id => @occasion_id)
    assert(!inv.errors.empty?, "invite should not have been created unless all fields were full.")
    inv = Invite.create(:inviter_id => @user.id, :occasion_id => @occasion_id)
    assert(!inv.errors.empty?, "invite should not have been created unless all fields were full.")
    inv = Invite.create(:inviter_id => @user.id, :invitee_id => @invitee.id)
    assert(!inv.errors.empty?, "invite should not have been created unless all fields were full.")
  end

  test "creates a notification" do
    invite=Invite.create!(:occasion => @occasion, :inviter => @user, :invitee => @invitee)
    notification = invite.notifications.first
    assert_not_nil(invite.notifications.first)
  end
  
  test "does not create notification" do 
    u = User.create!({first_name: "Jimmy", last_name: "Rogers"})
    invite = Invite.create!(:occasion => @occasion, :inviter => @user, :invitee => u)
    assert_nil(invite.notifications.first)
  end

  test "should send invitation even though inviter doesn't have mobile number" do
    u = User.create!({first_name: "Jimmy", last_name: "Rogers", :sourced_contacts_attributes => [
      { :first_name => "john",:last_name => 'doe', :contact_details_attributes => [
        { :field_name => "home", :field_value => "a@home.com"}
        ]
      }]
    })
    invite = Invite.create!(:occasion => @occasion, :inviter => u, :invitee => @invitee)
    notification = invite.notifications.first
    assert_not_nil(notification,"Should have sent an invite based upon another user's contact info")
    assert_equal(@user.mobile_number_contact_for(@invitee), notification.contact_detail)
  end

  test "invitation should create participations for inviter and invitee" do 
    invite=Invite.create!(:occasion => @occasion, :inviter => @user, :invitee => @invitee)
    assert_not_nil Participation.where(:user_id => @user.id, :occasion_id => @occasion.id).first
    assert_not_nil Participation.where(:user_id => @invitee.id, :occasion_id => @occasion.id).first
  end

end
