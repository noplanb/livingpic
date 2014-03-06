class Invite < ActiveRecord::Base

  attr_accessible :inviter, :invitee, :occasion, :invitee_id, :inviter_id, :occasion_id
  
  belongs_to :inviter, :class_name => 'User'
  belongs_to :invitee, :class_name => 'User'

  # These are more generic names for the two parties in the social action
  # These should be used for all social actions.  When I get the chance 
  # I may even change the other social actions to use these 
  alias :creator :inviter 
  alias :target :invitee

  belongs_to :occasion
  has_many :notifications,:as => :trigger, :dependent => :destroy
  has_many :participations, :as => :indication, :dependent => :destroy

  has_many :notifications, :as => :trigger

  # Have to include this even though it's not being used b/c of a bug in the way 
  # methods are bound to associations
  include EnumHandler
  
  scope :by, lambda { |user| where(:inviter_id => User.normalize_to_id(user)) }
  scope :to_u, lambda { |user| where(:invitee_id => User.normalize_to_id(user)) }
  scope :for, lambda { |occasion| where(:occasion_id => Occasion.normalize_to_id(occasion)) }

  validates_presence_of :inviter_id, :on => :create, :message => "can't be blank"
  validates_presence_of :invitee_id, :on => :create, :message => "can't be blank"
  validates_presence_of :occasion_id, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :invitee_id, :scope => [:inviter_id, :occasion_id], :on => :create, :message => "must be unique"
  
  after_create do 
    # Create participation records for both the inviter and the invitee
    Participation.find_or_create!(:user_id => invitee.id, :occasion_id => occasion.id, :indication => self)
    Participation.find_or_create!(:user_id => inviter.id, :occasion_id => occasion.id, :indication => self)
    Thread.new do 
      begin
        occasion.invite_added(self)
        # Trigger the appropriate notification 
        Notification.trigger(occasion,self)
      rescue  => e
        npb_mail("Invite #{id} error in after_create: #{e.message}")
      end
    end
  end
  
  def self.inviters_of_user_for_occasion(user, occasion)
    self.for(occasion).to_u(user).map{|i| i.inviter}
  end
  
  def hs
    "Invite [#{id}] from #{inviter.hs} to #{invitee.hs} for #{occasion.hs}"  
  end  

  # Check if this user has already been invited.
  def already_exists?
    Invite.exists?(:inviter_id => inviter_id, :invitee_id => invitee_id, :occasion_id => occasion_id)
  end

end
