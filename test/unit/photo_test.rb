require 'test_helper'

class PhotoTest < ActiveSupport::TestCase

  setup do 
    @user = User.create!(:first_name => "joe", :last_name => "blow")
    @user2 = User.create!(:first_name => "bubba", :last_name => "smith")
    @user3 = User.create!(:first_name => "nancy", :last_name => "jones")
    @photo = Photo.create!(:user_id => @user.id)
    @photo2 = Photo.create!(:user_id => @user2.id)
    @photo3 = Photo.create!(:user_id => @user3.id)
    @t1 = PhotoTagging.create!(:tagger_id => @user.id, :taggee_id => @user2.id, :photo_id => @photo.id)
    @t1 = PhotoTagging.create!(:tagger_id => @user3.id, :taggee_id => @user2.id, :photo_id => @photo3.id)
  end

  test "Photos by user" do
    pbu = Photo.by(@user)
    assert_equal(2, pbu.length)
    assert(pbu.include?(@photo), "Returned photos didn't include known photo by user")
    assert(!pbu.include?(@photo2), "Returned photos include known photo by different user")
  end

  test "Photos of user" do
    pbu = Photo.of_user(@user2)
    assert_equal(2, pbu.length)
    assert_equal([@photo,@photo3], pbu)
  end
end
