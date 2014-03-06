require 'test_helper'

class OccasionTest < ActiveSupport::TestCase

  setup  do
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
    
    @occasion = Occasion.create!(:name => "Party!",:user_id => @user.id, :city => "Boston")

  end

  test "occasion should create a participation event" do
    p = Participation.where(:user_id => @user.id, :occasion_id => @occasion.id).first
    assert_not_nil p
    assert p.is_occasion_creator?
  end

  test "occasion population estimate should return the mean value" do
    @occasion.pop_estimates << OccasionPopEstimate.new(:user_id => 1, :value => 80)
    @occasion.pop_estimates << OccasionPopEstimate.new(:user_id => 2, :value => 40)
    @occasion.pop_estimates << OccasionPopEstimate.new(:user_id => 1, :value => 30)
    assert_equal(50, @occasion.pop_estimate)
  end

end
