class Comment < ActiveRecord::Base

  include EnumHandler
  include NoPlanB::NamedScopes
  
  attr_accessible :photo_id, :user_id, :photo, :user, :body

  belongs_to :photo
  belongs_to :user
  alias :creator :user

  has_many :notifications, :as => :trigger

  scope :for, lambda { |photo| where(:photo_id => Photo.normalize_to_id(photo)) }
  scope :by, lambda { |user| where(:user_id => User.normalize_to_id(user)) }

  delegate :occasion, :to => :photo
  
  # Just to make sure we don't get the same message twice.  May remove b/c it could be expensive
  validates_uniqueness_of :body, :scope => [:user_id, :photo_id], :on => :create, :message => "must be unique"
  validates_presence_of :body, :on => :create, :message => "can't be blank"
  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  
  after_create do 
    create_participation_event
    photo.occasion.content_added(self)
  end
  
  def thread_participants
    photo.comments.map{|c| c.user}.uniq
  end
  
  # Pass back the core attributes and expand the user
  def attributes_for_app
    attributes.only("id","body","created_on").merge(:user => user.base_attributes_for_app)
  end

  def create_participation_event
    Participation.find_or_create!(:user_id => user_id, :occasion_id => photo.occasion_id, :indication => self)
  end

  def hs
    "Comment [#{id}] by #{creator} on #{photo.hs}"  
  end

end
