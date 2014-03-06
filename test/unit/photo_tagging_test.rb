require 'test_helper'

class PhotoTaggingTest < ActiveSupport::TestCase

  setup do 
    @user = User.create!(:first_name => "joe", :last_name => "blow")
    @user2 = User.create!(:first_name => "bubba", :last_name => "smith")
    @photo = Photo.create!(:user_id => @user.id)
    @photo2 = Photo.create!(:user_id => @user2.id)
    @t1 = PhotoTagging.create!(:tagger_id => @user.id, :taggee_id => @user2.id, :photo_id => @photo.id)
  end

  test "validation fails for incomplete records" do
    assert_raise(ActiveRecord::RecordInvalid) { PhotoTagging.create!(:tagger_id => @user.id, :taggee_id => @user2.id) }
    assert_raise(ActiveRecord::RecordInvalid) { PhotoTagging.create!(:tagger_id => @user.id, :photo_id => @photo.id) }
    assert_raise(ActiveRecord::RecordInvalid) { PhotoTagging.create!(:taggee_id => @user.id, :photo_id => @photo.id) }
  end

  test "only a single photo-tagging should be created for the same photo and tagger and taggee" do
    assert_raise(ActiveRecord::RecordInvalid,"Seemed we were able to create a duplicate photo tagging") { 
      PhotoTagging.create!(:tagger_id => @user.id, :taggee_id => @user2.id, :photo_id => @photo.id) 
    }
  end


end
