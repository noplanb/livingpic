require 'test_helper'

class ContactDetailTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  self.use_transactional_fixtures = false

  require "contact_record"
  require "contact_detail"

  setup do 
    @contact_record = ContactRecord.new
    # @base = ContactDetail.create(:field_name => "mobile", :field_value => "212 111 2222")
  end
  
  test "can't overwrite value and kind" do
    p1 = ContactDetail.new(:field_name => "home", :field_value => "212 111 2222")
    assert_raise(NoMethodError) { p1.value = "99" }
    assert_raise(NoMethodError) { p1.kind = :email }
  end

  test "stripped phone spaces" do
    p = ContactDetail.create(:field_name => "mobile", :field_value => "212 111 2222")
    assert_equal("2121112222", p.phone)
  end
  
  test "stripped phone parens and dashes" do 
    p = ContactDetail.create(:field_name => "mobile", :field_value => "(212) 111-2222")
    assert_equal("2121112222", p.phone)
  end
  
  test "removed country code with +1" do 
    p = ContactDetail.create(:field_name => "mobile", :field_value => "+98 212 111-2222")
    assert_equal("2121112222", p.phone)
    assert_equal("98",p.country_code.to_s)
  end
  
  test "removed country code with 011" do 
    p = ContactDetail.create(:field_name => "home", :field_value => "011 98 33 111-2222")
    assert_equal("331112222", p.phone)
    assert_equal("98",p.country_code.to_s)
  end
  
  test "saved kind as unknown phone" do
    p = ContactDetail.create(:field_value => "212 111 2222")
    assert p.is_phone?
    assert p.is_unknown_phone?
  end
  
  test "saved kind as email" do 
    p = ContactDetail.create(:field_value => "a@b.com")
    assert p.is_email?
    assert !p.is_phone?
  end
  
  test "saved value as mobile phone" do 
    p = ContactDetail.create(:field_name => "mobile", :field_value => "212 111 2222")
    assert p.is_mobile_phone?
  end
  
  test "saves iphone as mobile phone" do
    p = ContactDetail.create(:field_name => "iphone", :field_value => "(212) 111 2222")
    assert p.is_mobile_phone?    
  end
  
  test "saves cell as mobile phone" do
    p = ContactDetail.create(:field_name => "cell", :field_value => "(212) 111 2222")
    assert p.is_mobile_phone?    
  end
  
  test "saved value as other phone" do 
    p = ContactDetail.create(:field_name => "home", :field_value => "212 111 2222")
    assert p.is_other_phone?
  end
  
  test "similar details match" do
    p1 = ContactDetail.new(:field_name => "mobile", :field_value => "212 111 2222")
    p2 = ContactDetail.new(:field_name => "cell", :field_value => "212 111 2222")
    assert p1.matches?(p2)
  end
  
  test "different values don't match" do
    p1 = ContactDetail.new(:field_name => "home", :field_value => "212 111 2222")
    p2 = ContactDetail.new(:field_name => "cell", :field_value => "212 111 2222")
    p3 = ContactDetail.new(:field_name => "work", :field_value => "212 111 2222")
    p4 = ContactDetail.new(:field_name => "cell", :field_value => "212 111 2224")
    assert !p1.matches?(p2)
    assert p1.matches?(p3)
    assert !p1.matches?(p4)
    assert !p2.matches?(p3)
    assert !p2.matches?(p4)
    assert !p3.matches?(p4)
  end
  
  test "different details that kind of match" do
    p1 = ContactDetail.new(:field_name => "home", :field_value => "212 111 2222")
    p2 = ContactDetail.new(:field_name => "cell", :field_value => "212 111 2222")
    p3 = ContactDetail.new(:field_name => "work", :field_value => "212 111 2222")
    p4 = ContactDetail.new(:field_name => "cell", :field_value => "212 111 2224")
    assert p1.somewhat_matches?(p2)
    assert p1.somewhat_matches?(p3)
    assert !p1.somewhat_matches?(p4)
    assert p2.somewhat_matches?(p3)
    assert !p2.somewhat_matches?(p4)
    assert !p3.somewhat_matches?(p4)        
  end

  test "updates a detail record with newer info" do
    p1 = ContactDetail.new(:field_name => "home", :field_value => "212 111 2222")
    p2 = ContactDetail.new(:field_name => "cell", :field_value => "212 111 2222")
    updated = p1.update_if_necessary(p2)
    assert updated.include?(:field_name), "field name should have updated but didn't "
    assert updated.include?(:kind), "kind should have updated but didn't "
    assert !updated.include?(:field_value), "field value should not have updated but did"
    assert !updated.include?(:value), "value should not have updated but did"
  end
end
