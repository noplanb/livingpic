class OccasionPopEstimate < ActiveRecord::Base
  attr_accessible :user_id, :occasion_id, :value

  belongs_to :user
  belongs_to :occasion

  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_presence_of :occasion_id, :on => :create, :message => "can't be blank"
  validates_presence_of :value, :on => :create, :message => "can't be blank"
  # We will only save a single estimate per user


  # This will fail silently 
  # Returns the object created so you can check for errors
  def self.create_or_update(params)
    if e = first.where(:user_id => params[user_id],:occasion_id => params[occasion_id])
      e.update_attribute(:value,value)
    else
      e = create(params.only(:user_id,:occasion_id,:value))
    end
    e
  end

end
