class Like < ActiveRecord::Base

  include EnumHandler
  include NoPlanB::NamedScopes

  attr_accessible :photo_id, :user_id, :photo, :user

  belongs_to :photo
  belongs_to :user
  alias :creator :user

  validates_uniqueness_of :photo_id, :scope => [:user_id], :on => :create, :message => "must be unique"
  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_presence_of :photo_id, :on => :create, :message => "can't be blank"

  scope :for, lambda { |photo| where(:photo_id => Photo.normalize_to_id(photo)) }
  scope :by, lambda { |user| where(:user_id => User.normalize_to_id(user)) }

  delegate :occasion, :to => :photo

  after_create do
    create_participation_event
    photo.occasion.content_added(self)
  end

  def create_participation_event
    Participation.find_or_create!(:user_id => user_id, :occasion_id => photo.occasion_id, :indication => self)
  end

  def liker_attributes_for_app
    user.base_attributes_for_app
  end

  # the assumption is that this will go in the photo object - that's why we don't add the app info
  def attributes_for_app
    {:user => user.base_attributes_for_app, :id => id}
  end

  def hs
    "Like [#{id}] by #{creator} on #{photo.hs}"  
  end


end
