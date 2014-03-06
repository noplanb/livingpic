class Geolocation
  
  attr_accessor :latitude, :longitude
  def initialize(params)
    self.latitude = params[:latitude]
    self.longitude = params[:longitude]
  end

  EARTH_RADIUS_IN_MILES = 6371 
  PI = 3.141596
  
  def deg_to_rad(degrees)
    degrees * PI/180
  end
  
  def distance_from(p2)
    distance = Math.acos(Math.sin(deg_to_rad latitude)*Math.sin(deg_to_rad p2.latitude) +
                      Math.cos(deg_to_rad latitude)*Math.cos(deg_to_rad p2.latitude)*Math.cos(deg_to_rad(p2.longitude-longitude))) * R;
    return d;
    
  end

  def to_hash
    {latitude: @latitude, longitude:@longitude}
  end
  
  # Return a sample geolocation value in the US
  def self.sample
    new latitude:(32+8*rand), longitude: (-120 + 40*rand)
  end


end