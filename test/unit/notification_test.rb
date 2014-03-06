require 'test_helper'

class NotificationTest < ActiveSupport::TestCase

  setup do
    @user = User.create!( { :first_name => "Sally", :last_name => "may", :status => :active, :sourced_contacts_attributes =>  
      [
        { :first_name => "john",:last_name => 'doe', :contact_details_attributes => [
          { :field_name => "mobile", :field_value => "+12123334444"},
          { :field_name => "home", :field_value => "213-555-1999"},
          { :field_name => "home", :field_value => "a@home.com"},
          { :field_name => "work", :field_value => "b@work.com"},
        ]},
        { :first_name => "jane",:last_name => 'doe', :contact_details_attributes => [
          { :field_name => "work", :field_value => "jd@work.com"},
        ]},
      ]
    })

    @user2 = User.create!( { :first_name => "Betty", :last_name => "boop", :status => :active, :sourced_contacts_attributes =>  
      [
        { :first_name => "jane",:last_name => 'doe', :contact_details_attributes => [
          { :field_name => "work", :field_value => "jd@work.com"},
          { :field_name => "mobile", :field_value => "111 222 3333"},
        ]
      }
      ]
    })
    @contact = User.where(:first_name => 'John', :last_name => "Doe").first
    @contact2 = User.where(:first_name => 'jane', :last_name => "Doe").first
    @some_user = User.create(:first_name => 'Some', :last_name => "User")
    @mobile_contact = @user.mobile_number_contact_for(@contact)
    @occasion = Occasion.create!(:name => "Test", :user => @user)
  end

  test "contact detail set up" do
    assert_not_nil(@mobile_contact)
    assert("2123334444",@user.mobile_number_for(@contact))
  end

  test "initializes the recipient from contact detail if it isn't present" do
    n = Notification.create :occasion => @occasion,:contact_detail => @contact.contact_details.mobile_phone.first
    assert_equal(@contact, n.recipient)
  end

  test "kind of notification should be correct" do 
    n = Notification.create(:recipient => @contact, :contact_detail => @contact.contact_details.mobile_phone.first)    
    assert_equal(:sms, n.kind)
    n = Notification.create(:recipient => @contact, :contact_detail => @contact.contact_details.email.first)    
    assert_equal(:email, n.kind)  
  end

  test "contact_value should reflect contact_detail value" do 
    n = Notification.create(:recipient => @contact, :occasion => @occasion,:contact_detail => @contact.contact_details.mobile_phone.first)
    assert_equal(@mobile_contact.normalized_value, n.contact_value)
  end

  test "either contact_value or contact_detail should be set" do 
    n = Notification.create(:occasion => @occasion, :recipient => @some_user)
    assert(!n.errors.empty?,"Notification w/o contact detail or contact value should not be saved, but was")
  end

  test "should use contact value when possible" do
    @contact.mobile_number = "999999999"
    n = Notification.create(:recipient => @contact, :occasion => @occasion)
    assert_equal(@contact.mobile_number, n.contact_value)
  end

  test "should determine recipient from contact detail if not provided" do
    n = Notification.create(:occasion => @occasion, :contact_detail => @mobile_contact)
    assert_equal(@contact, n.recipient)
  end

  test "should use all contact details for user even if not in sender's sourced contacts" do
    n = Notification.create(:occasion => @occasion, :recipient => @contact2)
    assert_equal(@contact2.contact_details.mobile_phone.first, n.contact_detail)
  end

end
