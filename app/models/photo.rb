class Photo < ActiveRecord::Base
  attr_accessible :latitude, :longitude, :occasion, :occasion_id, :user,:user_id, :pic, :time, :test_seed, :caption, :aspect_ratio
  attr_accessor :test_seed

  belongs_to :user
  belongs_to :occasion
  alias :creator :user

  # Have to include this because of a weird interaction bug between enum_handler and the way methods are created in rails
  include EnumHandler

  has_many :taggings, :class_name => 'PhotoTagging', :dependent => :destroy
  alias :photo_taggings :taggings
  has_many :participations, :as => :indication    
  has_many :notifications, :as => :trigger

  has_many :comments, :dependent => :destroy
  has_many :likes, :dependent => :destroy

  include Paperclip::Glue
  
  # Indicate that we don't want to process anything in realtime.  We will spawn a task to perform the processing

  paperclip_extra_options = {}
  if APP_CONFIG[:use_s3]
    paperclip_extra_options = {
      storage: :s3,
      s3_credentials: "#{Rails.root}/config/s3.yml",
      s3_permissions: :public_read,
      bucket: APP_CONFIG[:s3_bucket]
    }
  end
  # NOTE: when only_process is set to an empty array, or left off completely, all processing is performed, so you hae to set it to 
  # some dummy element to not process anything...
  has_attached_file :pic, {:styles => { :phone => "960x960>", :thumb => "200" } ,:only_process => [:dummy]}.merge(paperclip_extra_options)

  include NoPlanB::NamedScopes
  scope :at, lambda { |occasion| where(:occasion_id => Occasion.normalize_to_id(occasion)) }
  scope :by, lambda { |user| where(:user_id => User.normalize_to_id(user)) }

  validates_presence_of :user_id, :on => :create, :message => "can't be blank", :unless => :test_seed
  validates_presence_of :occasion_id, :on => :create, :message => "can't be blank", :unless => :test_seed

  # This is a join with photo taggings
  scope :of, lambda { |user|  joins(:taggings).where(:photo_taggings => {:tagger_id => User.normalize_to_id(user) })}
  scope :since, lambda { |time| time ? where(["created_on > ?",time]) : all }

  before_create do 
    self.time ||= Time.now
    # Assign a default aspect ratio
    self.aspect_ratio = 0.75  
  end

  # FF: create the participation even after the photo has been fully processed!
  # after_create do
  #   create_participation_event
  #   occasion.content_added(self) if occasion
  # end
  
  after_create :create_photo_styles

  before_destroy do
    occasion && occasion.touch
  end

  def attributes_for_app(version=nil)
    r = attributes.only("id", "occasion_id", "time", "aspect_ratio", "caption")
    r = r.merge :url => pic.url(:phone), 
                # :size => pic_file_size, 
                :thumb_url  => pic.url(:thumb), 
                :creator => user.base_attributes_for_app, 
                :comments => comments.map(&:attributes_for_app), 
                :likes => likes.count,
                :likers => likes.map(&:liker_attributes_for_app)
    r
  end
  

  # I had to make this special method becuase paperclip cant find the image if I try in after_create observer
  def save_with_aspect_ratio
    p = save!
    save_aspect_ratio
  end
  
  def save_aspect_ratio
    # g = Paperclip::Geometry.from_file(pic)
    # g.auto_orient
    # a_r = g.aspect
    update_attribute(:aspect_ratio, pic.width.to_f / pic.height)
  end
    
  def is_saved_to_s3?
     !!APP_CONFIG[:use_s3]
  end 

  # This should be in an after_create event but we have separated it b/c in our dummy data creation we don't have an occasion id when we create the phohto
  def create_participation_event
    # FF 2013-12-16: Paperclip seems to do something funky with self, such that it is no longer necessarily considered to be a Photo object
    # i.e. it fails Photo === self.  So I will reload it here
    Participation.find_or_create!(:user_id => user_id, :occasion_id => occasion_id, :indication => Photo.find(self.id)) unless test_seed 
  end

  def create_photo_styles
    Thread.new do 
      logger.info "Spun off new thread to process styles for photo #{id}...."
      found = false
      # We need to check to make sure the picture is actually there before we continue because 
      # when the photo record is created the files are still being written...
      # Under normal processing, the photo is still uploading to S3 when this fires, so we'll sleep a bit
      # and give it time.  On our laptops it can take up to 60 seconds for it to upload....
      sleep_time = 10
      10.times do 
        is_saved_to_s3? ? sleep(sleep_time) : sleep(1) 
        if pic.exists?
          found = true
          break
        else
          # Wait for a few seconds and try again
          logger.warn "Couldn't find orginal file for photo #{id} to generate styles."
          sleep_time *= 1.5
        end
      end

      if not found
        logger.error ("original file for photo #{id} was not found - Can't generate styles")
        npb_mail "original file for photo #{id} was not found on S3 so Can't generate styles"
        return
      end

      begin
        # There can be a race condition in which the original is not copied yet
        # by the time we want to create the thumbnails...
        time = Time.now
        logger.info "Photo #{id} start processing thumb and phone version "
        pic.reprocess!(:thumb,:phone)
        create_participation_event
        occasion.content_added(self) if occasion
        logger.info "Photo #{id} processing done in #{Time.now-time}s"
      rescue  => e
        npb_mail "Error processing phone version of pic #{id} with error #{e}"
      end
    end
  end
  
  # Verify the state of all the photos in the db
  def self.verify_photos(reprocess=false)
    photo_stats = {:missing_original => [], :missing_phone_or_thumb => [], :square_thumb => [], :not_on_aws => [], :no_aspect_ratio => [], :reprocess_fail => []}
    
    all.each do |p|
      photo_stats[:missing_original] << p.id and next unless p.pic.exists?(:original)
      photo_stats[:no_aspect_ratio] << p.id if p.aspect_ratio.blank? 
      
      unless p.pic.exists?(:thumb) && p.pic.exists?(:phone)
        photo_stats[:missing_phone_or_thumb] << p.id
        next
      end
      
      unless p.pic(:thumb).match(/amazonaws/) && p.pic(:phone).match(/amazonaws/)
        photo_stats[:not_on_aws] << p.id
        next
      end      
      
      photo_stats[:square_thumb] << p.id if p.is_square?
    end
    
    photo_stats.keys.each{|type| puts "Found #{photo_stats[type].length} #{type}"}
    
    return photo_stats unless reprocess
    reprocess_keys = photo_stats.keys - [:missing_original]
    reprocess_list = []
    reprocess_keys.each{|type| reprocess_list += photo_stats[type]}
    reprocess_list.uniq!
    puts "Reprocessing #{reprocess_list.length} photos..."
    reprocess_list.each{|p_id| photo_stats[:reprocess_fail] << p_id unless Photo.find(p_id).reprocess_and_save_aspect}
    return photo_stats
  end
  
  def is_square?(type=:thumb)
    return false unless pic.exists?(type)
    
    temp_file = File.join(Rails.root, "tmp", "tmp_thumb.jpg")
    system "curl -o #{temp_file} #{pic(type)}"
    w = `identify -format '%[fx:w]' #{temp_file}`.to_i
    h = `identify -format '%[fx:h]' #{temp_file}`.to_i
    a = w.to_f/h
    puts a
    (1-a).abs < 0.1    
  end
  
  def reprocess_and_save_aspect
    if pic.reprocess!(:thumb, :phone)
      save_aspect_ratio
      return true
    else
      return false
    end
  end
  
  # NOT USED - KEEP FOR A BIT THEN REMOVE
  def all_processing_done
    logger.info("All photo processing done for #{id}.  Creating participation event and updating occasion #{occasion_id}")
    create_participation_event
    occasion.content_added(self) if occasion
  end

  def hs
    "Photo [#{id}] by #{creator.hs} in Occasion #{occasion.hs}"
  end
end

