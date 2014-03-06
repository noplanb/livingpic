class PhotoTagging < ActiveRecord::Base
  attr_accessible :tlx, :tly, :brx, :bry, :taggee_id, :tagger_id, :tagger, :taggee, :photo_id
  
  belongs_to :tagger, :class_name => 'User'
  belongs_to :taggee, :class_name => 'User'

  # Define these two aliases so that we can refer to any social action's initiator and the target individual this way, if there is one
  alias :creator :tagger
  alias :target :taggee

  belongs_to :photo
  has_many :participations, :as => :indication    

  delegate :occasion, :to => :photo

  validates_presence_of :photo_id, :on => :create, :message => "can't be blank"
  validates_presence_of :tagger_id, :on => :create, :message => "can't be blank"
  validates_presence_of :taggee_id, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :photo_id, :scope => [:tagger_id, :taggee_id], :on => :create, :message => "must be unique"

  scope :by, lambda { |id| where(:tagger_id => id)  }
  scope :of, lambda { |id| where(:taggee_id => id)  }
  scope :for, lambda { |id| where(:photo_id => id)  }

  include EnumHandler
  
  after_create do 
    # Create participation records for both the tagger and the taggee
    Participation.find_or_create!(:user_id => tagger.id, :occasion_id => photo.occasion_id, :indication => self)
    Participation.find_or_create!(:user_id => taggee.id, :occasion_id => photo.occasion_id, :indication => self)
    Notification.trigger(photo.occasion,self)
  end


  def hs
    "Tag [#{id}] where #{tagger.hs} tagged #{taggee.hs} in #{photo.hs}"
  end

end
