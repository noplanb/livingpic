require 'test_helper'

class ContactRecordTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  self.use_transactional_fixtures = false
  
  require "contact_record"
  require "contact_detail"
  
  SOURCED_CONTACTS = {
    # Correct info
    :correct => {:first_name => "john",:last_name => 'doe', :contact_details_attributes => [
      { :field_name => "mobile", :field_value => "+12123334444"},
      { :field_name => "home", :field_value => "213-555-1999"},
      { :field_name => "home", :field_value => "a@home.com"},
      { :field_name => "work", :field_value => "b@work.com"},
    ]},
    
    # 1 - duplicate correct info with just mobile
    :same_name_same_mobile => {:first_name => "John",:last_name => 'doe', :contact_details_attributes => [
      { :field_name => "mobile", :field_value => "+12123334444"},
    ]},
    
    # 2 - duplicate correct info with just home
    :same_name_and_home_phone => {:first_name => "JOHN",:last_name => 'DOE', :contact_details_attributes => [
      { :field_name => "home", :field_value => "2135551999"},
    ]},

    # 3 - Same home phone but different names
    :different_first_name_and_different_format_home => {:first_name => "Jonothon",:last_name => '', :contact_details_attributes => 
      [
        { :field_name => "home", :field_value => "(213) 555 1999"}
    ]},
    
    # duplicate correct info with just home with country code
    :same_name_and_home_with_country_code => {:first_name => "John",:last_name => 'doe', :contact_details_attributes => [
      { :field_name => "home", :field_value => "+12135551999"},
    ]},
    
    # same name but different home phone
    :same_name_different_home => {:first_name => "John",:last_name => 'doe', :contact_details_attributes => [
      { :field_name => "home", :field_value => "+12134444444"},
    ]},
    
    # same email but different name
    :different_name_same_email => {:first_name => "Joey",:last_name => 'spencer', :contact_details_attributes => [
      { :field_name => "home", :field_value => "a@home.com"},
    ]},
    
    # Same mobile phone but different name
    :different_name_same_mobile => {:first_name => "Johnny",:last_name => 'doll', :contact_details_attributes => [
      { :field_name => "mobile", :field_value => "+12123334444"},
    ]},
    
    :all_different => {:first_name => "Bubba",:last_name => 'smith', :contact_details_attributes => [
      { :field_name => "mobile", :field_value => "+19199994444"},
    ]},
    
    :same_but_with_different_field_name => {:first_name => "John",:last_name => 'doe', :contact_details_attributes => [
      { :field_name => "iphone", :field_value => "+12123334444"},
    ]},
    
  }
    
  BASE_USER = { :first_name => "Sally", :last_name => "may", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:correct]]}
  
  USERS = [
    
    # 0 different_name_same_email
    { :first_name => "bill", :last_name => "murray", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:different_name_same_email]] },
    
    # 1 same_name_same_mobile
    { :first_name => "June", :last_name => "Ward", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:same_name_same_mobile]] },
    
    # 2 - same_name_and_home_phone
    { :first_name => "Jenny", :last_name => "craig", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:same_name_and_home_phone]] },
    
    # 3 - different_first_name_and_different_format_home
    { :first_name => "Bob", :last_name => "Marley", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:different_first_name_and_different_format_home]] },
    
    # 4 - same_name_and_home_with_country_code
    { :first_name => "Bruce", :last_name => "Bell", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:same_name_and_home_with_country_code]] },
    
    # 5 different same_name_different_home
    { :first_name => "John", :last_name => "Adams", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:same_name_different_home]] },
    
    # 6 Same mobile phone but different name
    { :first_name => "Meg", :last_name => "ryan", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:different_name_same_mobile]] },
    
    #7 all different
    { :first_name => "jerry", :last_name => "lewis", :status => :active, :sourced_contacts_attributes => [SOURCED_CONTACTS[:all_different]] }
  ]
  
  setup do 
    @base_user = User.create BASE_USER
  end

  # The minus method subtracts the details of one contact record from another, returning the
  # remaining ones in a duplicate record
  test "the minus method works" do
    cr1 = ContactRecord.new(SOURCED_CONTACTS[:correct])
    cr2 = ContactRecord.new(SOURCED_CONTACTS[:same_name_same_mobile])
    assert_equal(3, (cr1-cr2).details.length)
    assert_nil( (cr1-cr2).details.detect { |cd| cd.matches? cr2.details.first } )
  end
  
  test "the & method" do
    cr1 = ContactRecord.new(SOURCED_CONTACTS[:correct])
    cr2 = ContactRecord.new(SOURCED_CONTACTS[:same_name_same_mobile])
    assert_equal(1, (cr1&cr2).details.length)
    assert( (cr1&cr2).details.detect { |cd| cd.matches? cr2.details.first } )    
  end
      
  test "set completed" do
    USERS.each do |user_params|
      User.create(user_params)
    end
    assert_equal(USERS.length + 1, User.active.count)
    assert_equal(12, ContactDetail.count)
  end
  
  test "invitee user created" do
    assert_equal(BASE_USER[:sourced_contacts_attributes].length, @base_user.sourced_contact_records.count)
    assert_equal(BASE_USER[:sourced_contacts_attributes].length,ContactRecord.count)
    assert_equal(BASE_USER[:sourced_contacts_attributes][0][:contact_details_attributes].length, ContactDetail.count)
    assert_equal(BASE_USER[:sourced_contacts_attributes][0][:contact_details_attributes].length, @base_user.sourced_contact_details.count)
  end
  
  test "finds user with different name and same email" do
    u1 = User.create(USERS[0])
    assert_equal(3, User.count)
    assert_equal(1, User.initialized.count)
    i1 = User.initialized.first
    assert_equal(u1.sourced_contact_records.first.user, i1)
  end
  
  test "finds user with same name and mobile" do 
    User.create(USERS[1])
    assert_equal(3, User.count)
    assert_equal(1, User.initialized.count)
  end
  
  test "finds user with same name and home" do
    User.create(USERS[2])
    assert_equal(3, User.count)
    assert_equal(1, User.initialized.count)
  end
  
  test "finds user with different first name and different format home" do
    User.create(USERS[3])
    assert_equal(4, User.count)
    assert_equal(2, User.initialized.count)
  end
  
  test "same_name_and_home_with_country_code" do 
    User.create(USERS[4])
    assert_equal(3, User.count)
    assert_equal(1, User.initialized.count)     
  end
  
  test "same_name_different_home" do 
    User.create(USERS[5])
    assert_equal(4, User.count)
    assert_equal(2, User.initialized.count)     
  end
  
  test "Same mobile phone but different name" do 
    User.create(USERS[6])
    assert_equal(3, User.count)
    assert_equal(1, User.initialized.count)     
  end
  
  test "all different" do 
    User.create(USERS[7])
    assert_equal(4, User.count)
    assert_equal(2, User.initialized.count)     
  end
  
     
  test "find existing contact from same source" do 
    assert ContactRecord.already_exists?( @base_user.id, @base_user.sourced_contacts.first),"Match failed on existing sourced contact from same user and same contact record"
    u1 = User.create(USERS[1])
    assert ContactRecord.already_exists?(u1.id,@base_user.sourced_contacts.first), "Match failed on existing sourced contact but with updated fields"
  end
  
  test "existing contact from different source doesn't match" do 
    assert !ContactRecord.already_exists?( @base_user.id+1, @base_user.sourced_contacts.first),"Erroneous match on existing sourced contact from different source"
  end
  
  test "verify contact from different source doesn't match" do 
    assert !ContactRecord.already_exists?( @base_user.id+1, ContactRecord.new(SOURCED_CONTACTS[:same_name_same_mobile])),"Match failed on different contact from different source"
  end
  
  test "verify that existing contact is updated as necessary" do
    u1 = User.create(USERS[1])
    existing_contact = ContactRecord.already_exists?(u1.id,@base_user.sourced_contacts.first)
    updated_contact_details = existing_contact.update_if_necessary(@base_user.sourced_contacts.first)
    assert_equal(3, updated_contact_details.count)
  end

  test "verify we find shared contact details" do 
      assert_equal(1, ContactRecord.shared_contact_details(ContactRecord.new(SOURCED_CONTACTS[:correct]),
        ContactRecord.new(SOURCED_CONTACTS[:same_name_same_mobile])).length)
  end
  
  test "verify contacts in one record but not in another" do
    cr1 = ContactRecord.new(SOURCED_CONTACTS[:correct])
    cr2 = cr1.dup
    assert_equal(4, cr1.details.length)
    cr2.details = [cr1.details.first]
    assert_equal(cr1.details.length - cr2.details.length, (cr1 - cr2).details.length)
  end

  test "update existing record if we get new information" do
    cr1 = ContactRecord.new(SOURCED_CONTACTS[:same_name_same_mobile])
    cr2 = ContactRecord.new(SOURCED_CONTACTS[:same_but_with_different_field_name])
    updated_details = cr1.update_if_necessary(cr2)
    assert_equal(1, updated_details.length)
    assert_equal(cr2.details.first.field_name, updated_details.first.field_name)
  end
  
  test "add to existing record if we get new information" do
    cr1 = ContactRecord.new(SOURCED_CONTACTS[:same_name_same_mobile])
    cr2 = ContactRecord.new(SOURCED_CONTACTS[:correct])
    updated_details = cr1.update_if_necessary(cr2)
    assert_equal(3, updated_details.length)
    assert_equal(0,(cr2-cr1).details.length)
  end

  test "create or update" do
    u1 = User.create!(:first_name => "test", :last_name => "user")
    cr1 = ContactRecord.create_or_update(SOURCED_CONTACTS[:same_name_same_mobile].merge(:source_id => u1.id))
    u1.reload
    assert_equal(1, u1.sourced_contacts.length)
    assert_not_nil(cr1.id)
    # This one should just update
    cr2 = ContactRecord.create_or_update(SOURCED_CONTACTS[:correct].merge(:source_id => u1.id))
    cr1.reload
    assert_equal(cr1, cr2)
    assert_equal(4, cr1.details.length)
    assert_equal(1, u1.sourced_contacts.length)
    # Now, let's create a contact for a second user and make sure that it doesn't affect the first user
    u2 = User.create!(:first_name => "anothertest", :last_name => "user")
    cr2 = ContactRecord.create_or_update(SOURCED_CONTACTS[:correct].merge(:source_id => u2.id))
    assert_equal(4, cr1.details.length)
    assert_equal(1, u1.sourced_contacts.length)    
  end

end
