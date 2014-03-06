class Device < ActiveRecord::Base
  include EnumHandler
  
  attr_accessible :platform, :version, :user_id

  belongs_to :user
  validates_presence_of :platform, :on => :create, :message => "can't be blank"
  validates_presence_of :version, :on => :create, :message => "can't be blank"
  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :platform, :scope => [:user_id,:version], :on => :create, :message => "^Combination of platform, user_id, and version must be unique"  

  before_validation do
    self.platform.downcase! if self.platform
  end
  
  def self.make_current(params)
    # If the device exists for the user and is not last then destroy it and add it again to make it last.
    result = nil
    if match = where(params).first
      if match == User.find(params[:user_id]).devices.last
        result = match
      else
        match.destroy
        result = create!(params)
      end
    else
      result = create!(params)
    end
    result
  end
  
  def is_ios?
    !!platform.match(/^(iphone|ios|ipad|ipod)/i)
  end

  def is_android?
    platform == "android"
  end
end
