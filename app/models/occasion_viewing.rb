class OccasionViewing < ActiveRecord::Base

  attr_accessible :user_id, :occasion_id, :time, :user, :occasion
  include EnumHandler  

  scope :of, lambda { |occasion| where(:occasion_id => Occasion.normalize_to_id(occasion)) }
  scope :by, lambda { |user| where(:user_id => User.normalize_to_id(user)) }

  before_save do
    self.time ||= Time.now
  end

  def now!
    update_attribute(:time,Time.now)  
  end

end
