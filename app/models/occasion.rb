class Occasion < ActiveRecord::Base
  
  
  include EnumHandler
  attr_accessible :latitude, :longitude, :name, :start_time, :end_time, :user_id, :user, :city
  
  belongs_to :user
  has_many :photos, :dependent => :destroy
  has_many :comments, :through => :photos
  has_many :likes, :through => :photos
  has_many :pop_estimates, :class_name => "OccasionPopEstimate", :dependent => :destroy
  has_many :participations, :dependent => :destroy 
  has_many :invites, :dependent => :destroy
  has_many :photo_taggings, :through => :photos, :source => :taggings
  has_many :viewings, :class_name => "OccasionViewing", :dependent => :destroy
  has_many :notifications,:dependent => :destroy

  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_presence_of :name, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :name, :scope => [:user_id], :on => :create, :message => "must be unique"

  reverse_geocoded_by :latitude, :longitude do |obj,results|
    if geo = results.first
      obj.city = geo.city
    end
  end
  
  def self.get_or_create(params)
    user = User.find(params[:user_id])
    occs = user.relevant_occasions.select{|o| o.name == params[:name]}
    raise "User #{user.hs} is participating in #{occs.length} occasions with the same name: #{params[:name]}." if occs.length > 1
    occs.first || create!(params)
  end
  
  # We only do the geocoding if the city name is blank - this allows us to hack
  # around the geocoding by providing a city name in tests, etc.
  # In theory, though, the controller shouldn't be providing the city...
  after_validation do |occ|
    reverse_geocode if have_geolocation? && city.blank?
    occ.update_attribute(:start_time, Time.now) unless occ.start_time
  end
    
  # If the user created the occasion, then he's probably attending it
  after_create do 
    Participation.find_or_create!(:user_id => user_id, :occasion_id => id, :indication => self)
    update_attribute(:content_updated_on,created_on)
  end

  after_initialize do 
    self.content_updated_on ||= created_on
  end

  # Merge the second occasion into the first.  The merge includes:
  # photos
  # participants
  def self.merge
      
  end

  # Define a nearness in miles, that is, how far away something has to be to be considered near the user...
  SEARCH_RADIUS_MILES = 1.0
  # Find all the occasions that have been registered in the last x hours near the indicated latitude and longitude
  # Assumed to be in radians!  We're approximating here - assuming the curviture of earth is unimportant
  RADIUS_OF_EARTH = 6731  # in miles
  SEARCH_DEGREES = 180.0*SEARCH_RADIUS_MILES/RADIUS_OF_EARTH
  
  def self.near(parameters)
    lat,long = params[:latitude],params[:longitude]
    # GARF - this is incorrect if we're near the meridian where we go from 180 to -180
    # TODO - include the start time/end time in this somehow too - we don't know how long events take, but we don't want
    # to include an event that was days ago.  We'll add this as we get more events
    search_degrees = SEARCH_DEGREES
    found = []
    while found.length > 0 && search_degrees < 10*SEARCH_DEGREES
      found = all.where(["latitude > ? and latitude < ? and longitude > ? and longitude < ?", lat - search_degrees, lat + search_degrees, long - search_degrees, long + search_degrees])
      search_degrees *= 2
    end
    # TODO - return the events by distance from current point
    found
  end
  
  def pop_estimate
    pop_estimates.map(&:value).mean
  end

  def have_geolocation?
    !latitude.nil? && !longitude.nil?  
  end

  # Return all the occasion participants.  In theory this should be equal to the invitees + creator, so selecting from the invites
  # may be a faster way of getting to it
  def participants
    User.find Participation.select("distinct user_id").where(:occasion_id => id).all.map(&:user_id)
    # participations.map(&:user).uniq
  end

  # picture that represents the occasion from the point of view of the user.
  # Sani - I set it to just show the most recent photo based on experience at powderfiesta
  def photo_for_user(user=nil)
    return photos.last
    photo = 
      unless photos.empty? 
        if not (took_photos = photos.by(user)).empty?
          took_photos.last
        elsif not (in_photos = photos.of(user)).empty? 
          in_photos.last
        else 
          photos.last
        end
      else
        nil
      end
  end
  
  def destroy_all_photos
    photos.each{|p| p.destroy}
  end
  
  # This can return either a path or a URL, depending upon where the image is stored (e.g. on S3 it'll return the URL, I think)
  def thumbnail_path_for_user(user)
    (photo = photo_for_user(user)) && occasion_thumbnail(photo)
  end

  def occasion_thumbnail(photo)
    # for backwards compatibility with thumb which used to be square and the the new thumb which isnt.
    if File.exists?(photo.pic.path(:thumb_sq))
      photo.pic.url(:thumb_sq)
    else
      photo.pic.url(:thumb)
    end
  end
  
  # Define the subset of attributes that are useful for the app to know, just to keep the noise level a bit lower
  def attributes_for_app(version=nil)
    cache_dir = File.join(Rails.root,"tmp","occasions-cache")
    Dir.mkdir(cache_dir) unless File.exist?(cache_dir) 
    cache_filename = File.join(cache_dir,"occasion.#{id}")
    if File.exist?(cache_filename) 
      x = File.read(cache_filename)
      cache = JSON.load(x).symbolize_keys
      if content_updated_on && Time.parse(cache[:updated_on]) >= content_updated_on
        return cache[:content]
      end
    end
    # NOTE - we translate the content_updated_on to version so that the client can compare
    # this to a previous version and see if it has to do anything
    r = attributes.only("id","name", "start_time","city")
    r = r.merge :participants => participants.map{|p| p.base_attributes_for_app}, 
                :photos => photos.map{ |p| p.attributes_for_app(version) }.reverse, 
                :thumb_id => photos.last && photos.last.id,
                :version => content_updated_on.to_i
    File.open(cache_filename,"w") do |f|
      f.write( {updated_on: Time.now, content: r}.to_json)
    end
    r
  end
    
  # Farhad_todo!  
  # Please replace this stub.
  # Need back end smarts to figure out the photos for my occasion and prioritize. 
  # From the spec here is what we think we ultimately might want to try:
  #   1) Pics that include you taken by others. I am guessing the narcissistic pleasure will be high.
  #   2) Pics taken by you interspersed with pics taken by others that include people we know you know 
  #      based on the social graph prioritized by how close the subjects are to you on the social graph and number of likes. 
  #  
  # For the first release we can keep it simple:
  #   1) Pics that include you taken by others. I am guessing the narcissistic pleasure will be high.
  #   2) Pics taken by you interspersed with pics taken by others (dont worry about whether you know them or not). 
  def gallery_for_user(user)
    # GARF: The cachebusting timestamp is for testing worst case load times remove before production!!!
    # The map is butt slow (1 second for 700 pics) and should not be used!
    # photos.first(100).map{|p| p.pic.url(:thumb) +  "-"  + Time.now.to_i.to_s}
    photos.order("created_on DESC").map{|p| p.attributes_for_app }
  end

  def last_viewed_by(user)
    last_viewing = viewings.by(user).first and last_viewing.time
  end

  # Return the new photos for a user for this occasion, since the user last viewed this occasion
  def new_photos_for(user)
    new_content_for(user,:photo)  
  end
  
  def new_comments_for(user)
    new_content_for(user,:comment)  
  end

  def new_likes_for(user)
    new_content_for(user,:like)  
  end

  # returns new content of the indicated type for the user
  def new_content_for(user,type=nil)
    user_id = User.normalize_to_id(user)
    case type
    when :comment
      comments.created_since(last_viewed_by(user))
    when :photo
      photos.created_since(last_viewed_by(user))
    when :like
      likes.created_since(last_viewed_by(user))
    else
      Participation.content_creation.in(self).map(&:indication)
    end.select{ |c| c.user_id != user_id }

  end

  # Indicate that this occasion's gallery has been viewed by the user
  def viewed_by(user)
    (viewing = viewings.by(user).first) ? viewing.now! : OccasionViewing.create!(:user_id => user.id, :occasion_id => id) 
  end
  
  # A photo or comment has been added to this occasion. Notify various participants as needed
  def content_added(content)
    update_attribute(:content_updated_on, content.created_on)
    notifications = []
    participants.each do |participant|
      next if participant.id == content.user_id
      next unless Notification.trigger(self, content, :recipient => participant, :sender => content.creator)
      notifications << participant.id  
    end
    notifications
  end

  def invite_added(invite)
    update_content_updated_on(invite.created_on)
  end

  def hs
    "[#{id}]#{name}"
  end  
  
  # Figure out when content was last added to this occasion
  # GARF - for now just adding comments and photos
  def calc_content_updated_on
    time = created_on
    unless photos.empty? 
      time = photos.last.created_on
      photos.each do |photo|
        unless photo.comments.empty?
          time = photo.comments.last.created_on if photo.comments.last.created_on > time
        end
        unless photo.likes.empty?
          time = photo.likes.last.created_on if photo.likes.last.created_on > time
        end
      end

    end
    invites.last.created_on > time ? invites.last.created_on : time
  end

  def touch
    update_content_updated_on(Time.now)  
  end

  def update_content_updated_on(time=nil)
    time ||= calc_content_updated_on
    time  > content_updated_on and update_attribute(:content_updated_on,time)
  end


  # SOME STATISTICAL STUFF

  def invitees
    invites.map(&:invitee).uniq
  end

  def joiners
    invitees.select{ |user| last_viewed_by(user) }  
  end

end
