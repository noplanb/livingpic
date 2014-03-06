class Invite < ActiveRecord::Base
  belongs_to :occasion
  belongs_to :inviter, :class_name => 'User'
  belongs_to :invitee, :class_name => 'User'
  
  attr_accessible :invitee_id, :inviter_id
end
