class User < ActiveRecord::Base

  require "digest"

  include EnumHandler  
  include NoPlanB::NameUtils

  require "user_modules/info"
  include UserModules::Info

  include PhoneHandling

  attr_accessible :campaign, :email, :first_name, :last_name, :mobile_number, :password, :registered_on, :status, :app_version, :push_enabled, :sourced_contacts_attributes

  has_many :devices, :dependent => :destroy
    
  # Note that the dependent => destroy is only useful for development cleanup 
  # We should never destroy a user.  If we did, we'd have to take out all of 
  # these dependencies
  has_many :photos, :dependent => :destroy

  # these are the photos the user has tagged someone in
  has_many :photo_taggings, :foreign_key => 'tagger_id', :dependent => :destroy
  has_many :photos_tagged, :class_name => 'Photo', :through => :photo_taggings, :source=> 'photo'
  
  # these are the photos the user has been tagged in by someone
  has_many :photo_taggings_in, :class_name => "PhotoTagging", :foreign_key => 'taggee_id', :dependent => :destroy
  has_many :photos_tagged_in, :class_name => 'Photo', :through => :photo_taggings_in, :source=> 'photo'

  has_many :invites, :foreign_key => :inviter_id, :dependent => :destroy
  has_many :invitings, :class_name => 'Invite', :foreign_key => :invitee_id, :dependent => :destroy

  has_many :participations, :dependent => :destroy
  has_many :created_occasions, :class_name => "Occasion", :dependent => :destroy 
  has_many :occasion_pop_estimates, :class_name => "OccasionPopEstimate", :dependent => :destroy
  has_many :occasion_viewings, :dependent => :destroy
  
  has_many :likes, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  has_many :notifications, :foreign_key => "recipient_id", :dependent => :destroy 

  # This can be confusing:  A user both sources contacts (from his address book) and can have contact records assigned to him 
  # (where we think a contact record points to this user).  
  # The contact record's source_id points to who's address book it comes from and the user_id represents who it points to
  # This is a social graph in a primitive sense (that is, we may change it later when we need it more and if this gets too heavy)
  has_many :contact_records, :dependent => :destroy
  has_many :contact_details, :through => :contact_records
  
  has_many :sourced_contacts, :class_name => "ContactRecord", :foreign_key => "source_id", :dependent => :destroy
  alias :sourced_contact_records :sourced_contacts
  has_many :sourced_contact_details, :class_name => "ContactDetail", :through => :sourced_contacts, :source => :contact_details
  
  scope :with_sourced_contacts, :joins  => "INNER JOIN contact_records ON contact_records.source_id = users.id", :group => :id
  scope :with_push_token, :conditions => "push_token IS NOT NULL"
  scope :opted_out, :conditions  => {:notification_preference => :none}

  # pending means we have contacted him
  define_enum :status,[:initialized, :contact_attempted, :contacted, :active, :suspended], :sets => {:registered => [:active,:suspended]}, :primary => true
  define_enum :kind, [:normal,:test]
  define_enum :notification_preference, [:sms, :email, :push, :none, :default]
  
  before_save do 
    self.first_name = normalize_case(first_name)
    self.last_name = normalize_case(last_name)
    self.mobile_number = normalize_phone_number(mobile_number)
    self.status ||= :initialized
    if status == :active
      self.registered_on ||= Time.now 
      # Dont create a default occasion for the time being. Also this should probably be in after_save.
      # create_default_occasion unless default_occasion
    end
  end

  after_initialize do 
    self.auth_token ||= Digest::SHA1.hexdigest(Time.now.to_i.to_s + NoPlanB::TextUtils.random_string(10))
  end

  # This should never be an issue!
  validates_uniqueness_of :auth_token, :on => :create, :message => "must be unique"


  accepts_nested_attributes_for :sourced_contacts
  
  # We find by the mobile number or email as long as either the first name or last name match
  def self.find_or_create!(params)
      ((params[:email] && where(:email => params[:email]).first) || 
             (params[:mobile_number] && where(:mobile_number => params[:mobile_number]).first)) && 
      ((params[:first_name] && where(:first_name => params[:first_name]).first) || 
        (params[:last_name] && where(:last_name => params[:last_name]).first)) || create!(params)
  end
  
  # The user that corresponds to the system administrator
  def self.system_admin
    User.find_by_email(APP_CONFIG[:admin_email])
  end

  # =============================================================================================================================
  # = Garf These should already be in our standard model or should be added to our standard madel Fix when Farhad brings it in. =
  # =============================================================================================================================
  
  def first_li
    "#{first_name} #{last_name[0]}"
  end
  
  # TODO - should be called full_name to be consistent with first_name, last_name, etc.
  def fullname
    "#{first_name} #{last_name}"
  end
  alias_method :name, :fullname

  def short_name
    first_name.or_if_blank(last_name)  
  end
  
  def is_admin?
    APP_CONFIG[:admin_ids].include? id
  end
  
  def self.admin_users
    find APP_CONFIG[:admin_ids]
  end
  
  # NOTE: We overwrite what the user's may have indicated as the label for the phone number.  If the user responds
  # to an sms on this number, we consider it to be their mobile number
  def responded_to_notification(notification)
    # MARKER - that the value changed
    if notification.is_email? && notification.contact_value != email
      log_event("User #{self.log_info} email updated from [#{email || 'null'}] to [#{notification.contact_value}]")
      self.update_attribute(:email,notification.contact_value)
    elsif notification.is_sms? && notification.contact_value != mobile_number
      log_event("User #{self.log_info} mobile_number updated from [#{mobile_number || 'null'}] to [#{notification.contact_value}]")
      self.update_attribute(:mobile_number,notification.contact_value)
    end
    # update the user's status so we know that he has responded to a notification
    if status == :contact_attempted || status == :initialized
      update_attribute(:status,:contacted)  
    end
  end
  
  def unviewed_notifications
    notifications.since(last_active_on)
  end

  def num_unviewed_notifications
    notifications.since(last_active_on).count
  end
  
  # Note that we have attempted to contact this user
  # Just update the status so we know
  def contact_attempted!
    if status == :initialized then update_attribute(:status,:contact_attempted); end
  end

  # These is the representation of the key user parameters fo the app.  We don't want to send all the cruft up there, just stuff
  # that's useful
  def attributes_for_app
    attributes.only("id","first_name", "last_name", "mobile_number").merge("registered" => is_registered?, "num_occasions" => relevant_occasions.length )
  end
  
  # These is the minimal representation of the for the app, so we don't leak mobile numbers and such
  def base_attributes_for_app
    attributes.only("id","first_name", "last_name")
  end
  
  def update_last_activity_date
    update_attribute(:last_active_on, Time.now)
  end

  #######################
  #  Contacts
  #######################

 # Return what this user thinks is the mobile number for a particular contact
  def mobile_number_contact_for(contact_user)
    contact_user_id = User.normalize_to_id(contact_user)
    contact_record = sourced_contacts.for(contact_user_id).first and contact_record.details.mobile_phone.not_bad.first
  end

  def mobile_number_for(contact_user)
    m = mobile_number_contact_for(contact_user) and m.value
  end

  # Return the users who are this person's contacts
  def contacts
    contact_records.map(&:user)
  end
  
  # We're guessing at the mobile phone number
  # Right now it's a simple voting mechanism, ignoring those that could be bad
  # but in the future we could do something else
  def mobile_number_contact_guess
    mobile_numbers = {}
    # Let's see what the contact records think the mobile number for this user
    # should be
    contact_records.each do |cr|
      cr.details.mobile_phone.not_bad.each do |cd|
        mobile_numbers[cd] ||= 0
        mobile_numbers[cd] += 1 
      end
    end
    # Return the last one
    best = mobile_numbers.sort { |a,b| a[1] <=> b[1] }.last and best[0]
  end
  
  def mobile_number_guess
    m = mobile_number_contact_guess and m.value
  end

  # Should this user be invited to the indicated occasion?
  # Right now, yes, even if it's a duplicate invitation
  def should_be_invited?(occasion)
    true
  end
  
  def has_app?
    !app_version.blank?
  end

  def notify_via_push?
    notification_preference == :push || (self.push_token && !notification_preference)
  end

  def opted_out_of_notifications?
    notification_preference == :none
  end

  # =============
  # = Occasions =
  # =============

  # Create the user's default ocasion
  def create_default_occasion
    create_occasion(APP_CONFIG[:default_occasion_name])
  end

  def default_occasion
    occasions.where(:name => APP_CONFIG[:default_occasion_name])
  end
  
  # Should return the occasion if the occasion was created
  def create_occasion(name)
    Occasion.create :name => name, :user_id => id
  end

  def invite(invitee,occasion)
    invitee_id = User.normalize_to_id(invitee)
    occasion_id = Occasion.normalize_to_id(occasion)
    # We allow this to fail by validation in case the invite already exists
    Invite.create :invitee_id => invitee_id, :occasion_id => occasion_id, :inviter_id => id
  end

  # Let's assume a user can uninvite someone who was accidentally invited
  # GARF : Used for testing - for product if we ever get there, we'll do it 
  # some other way to preserve history, for example by adding a status
  # to a participation
  def uninvite(invitee,occasion)
    if i = invites.for(occasion).to_u(invitee)
      i.first.destroy
    end
  end

  # Return the user's relevant occasions, that is, all those he has participated in
  # We return them in reverse order, so the most recent is presented first
  def relevant_occasions
    Occasion.find(participations.map(&:occasion_id).uniq).sort_by(&:created_on).reverse
  end
  alias_method :occasions, :relevant_occasions

  def has_access_to_occasion?(occasion)
    occasion_id = Occasion.normalize_to_id(occasion)  
    participations.map(&:occasion_id).include?(occasion_id)
  end

  def has_participated_in?(occasion)
    !participations.active.in(occasion).empty?
  end

  def last_viewed(occasion)
    occasion_last_viewed_by(self)
  end

  def new_photos_for(occasion)
    occasion.new_photos_for(self)
  end

  # =============
  # = Photos    =
  # =============

  def add_photo(occasion)
    Photo.create(:user_id => id, :occasion_id => Occasion.normalize_to_id(occasion))
  end

  def tag_photo(photo,taggee)
    PhotoTagging.create(:tagger_id => id, :photo_id => Photo.normalize_to_id(photo), :taggee_id => User.normalize_to_id(taggee) )
  end

  def hs
    "[#{id}]#{is_registered? ? 'R' : 'U'} #{name}"
  end

  # =============
  # = Devices    =
  # =============

  # Expect params to have keys: :platform, :platform_version
  def has_device(params)
    # NOTE: we allow that this can fail, which generally means the device is already there
    Device.make_current(platform: params[:platform], version: params[:platform_version], user_id: id)
  end

  def device
    devices.last
  end

  # =============
  # = TEST    =
  # =============

  # Reset the user so it seems like he's invited but otherwise hasn't launched the app
  def reset
    self.status = :initialized
    self.app_version = nil
    self.notification_preference = nil
    self.push_token = nil
    self.registered_on = nil
    self.devices = []
    save!
  end

end
