require 'test_helper'

class UserTest < ActiveSupport::TestCase
  
  test "capitalization" do
    u1 = User.create({:first_name => "joe", :last_name  => "blow"})
    u2 = User.create({:first_name => "JOHN", :last_name => "rED"})
    assert_equal("Joe", u1.first_name)
    assert_equal("Blow", u1.last_name)
    assert_equal("John", u2.first_name)
    assert_equal("Red", u2.last_name)
  end

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
    @contact = User.where(:first_name => 'John', :last_name => "Doe").first
    @occasion = Occasion.create!(:name => "Party!",:user_id => @user.id)
    @mobile_contact = @user.mobile_number_contact_for(@contact)
  end

  test "contact created" do 
    assert_not_nil(@contact,"Contact user was not created")
    assert_nil(@contact.mobile_number)
    assert_not_nil(@contact.contact_details.mobile_phone.first)
  end

  test "find contacts mobile number" do
    assert_equal("2123334444", @user.mobile_number_for(@contact))
  end

  test "find mobile number"  do 
    assert_equal("2123334444",@contact.mobile_number_guess)
  end

  test "update mobile number if notification replied to" do
    n = Notification.trigger(@occasion, @user.invite(@contact,@occasion))
    @contact.responded_to_notification(n)
    assert_equal(@mobile_contact.normalized_value, @contact.mobile_number)
  end

  test "invite a user should create invitation and notification" do
    invite = @user.invite(@contact,@occasion)
    assert_not_nil(invite)
    n = invite.notifications.first
    assert_not_nil(n)
    assert_equal(@contact.contact_details.mobile_phone.first,n.contact_detail)
  end
end
