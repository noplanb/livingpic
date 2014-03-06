class ContactRecord < ActiveRecord::Base
  require_dependency File.join(File.dirname(__FILE__),"contact_record","devices")
  extend ContactRecordExtension::Devices

  # I have to include this here b/c ActiveRecord::Relation seems to respond to has_enums but 
  # doesn't have it.  Very curious.
  include EnumHandler
  include NoPlanB::NameUtils
  
  attr_accessible :first_name, :last_name, :contact_details_attributes, :source_id
  
  has_many :contact_details, :dependent => :destroy
  alias :details :contact_details
  alias :details= :contact_details=

  accepts_nested_attributes_for :contact_details

  scope :sourced_by, lambda { |user| where(:source_id => User.normalize_to_id(user)) }
  scope :for, lambda { |user| where(:user_id => User.normalize_to_id(user)) }
  
  # The user is who we think this record points to, the source is who provided us with this contact
  belongs_to :user
  belongs_to :source, :class_name => "User"

  after_create do 
    if existing_user = existing_user_match
      update_attribute(:user_id,existing_user.id)
    else
      # Create the user record in initialized state
      update_attribute(:user_id,User.create(:first_name => first_name, :last_name => last_name, :status => :initialized).id)
    end
  end

  before_save do 
    self.first_name = normalize_case(first_name)
    self.last_name = normalize_case(last_name)
  end
  
  before_validation do
    remove_blank_contacts
  end
  
  # Check to see if this contact already exists for this source - we only consider an exact match for the name, 
  # or else the unique identifiers (email & mobile phone number), in case the name was updated
  # GARF: there exists a small chance that there will be two people with exactly the same name but different contacts
  # Returns the existing contact record
  def self.already_exists?(source_id,contact_record)
    found = nil
    sourced_records = sourced_by(source_id)
    if found = sourced_records.detect {|sr| sr.first_name == contact_record.first_name && sr.last_name == contact_record.last_name }
      return found
    end
    
    sourced_by(source_id).map{ |cr| cr.details }.flatten.each do |ocd|
      contact_record.details.each do |cd|
        found = ocd.contact_record and break if cd.is_unique_identifier? && ocd.is_unique_identifier? && cd.value == ocd.value
      end
    end
    found
  end
    
  def already_exists?
    self.class.already_exists?(source_id,self)
  end
  
    
  # Update the contact record if necessary
  # We match contact details, and if the new contact detail isn't there we create a new one
  # Returns an array of details that were changed  
  # TODO - should I be updating the first name or last name here also?  I am, assuming that the new contact record is
  #        newer than the existing one
  # NOTE: This assumes the contact records have matched already, e.g already_exists? has been run
  def update_if_necessary(new_contact_record)
    matched = []
    updated_details = []
    self.first_name = new_contact_record.first_name
    self.last_name = new_contact_record.last_name
    
    new_contact_record.details.each do |ncd|
      details.each do |ocd|
        matched << [ocd,ncd] and break if ocd.matches?(ncd)
      end
    end
    # Update the matched records if necessary
    matched.each do |ocd,ncd|
      if not ocd.update_if_necessary(ncd).empty?
        updated_details << ocd
      end
    end
    # Also add the new contact details that we are adding
    # We need to dup to make sure we don't overwrite the original
    
    (new_contact_record.details - matched.column(1)).each do |ncd| 
      self.details << ncd.dup
      updated_details << self.details.last
    end    
    updated_details
  end
  
  # Create this contact, or update it if necessary.  
  # First check if it exists, and if so, check to see if it needs to be upaded.  
  # Create it if it doesn't exist
  # Returns the contact that was updated or saved
  def self.create_or_update(params)
    cr = new(params)
    if ocr = cr.already_exists?
      ocr.update_if_necessary(cr)
      return ocr
    else
      cr.save!
      cr
    end
  end
  
  # returns the shared contacts from the first contact record if it also 
  # exists in the second contact record
  def self.shared_contact_details(contact_record_1,contact_record_2)
    shared_contacts = []
    contact_record_1.details.each do |cr1|
      contact_record_2.details.each do |cr2|
        shared_contacts << cr1 and break if cr1.matches?(cr2)
      end
    end
    shared_contacts
  end

  # Returns a new contact record that has the contact details shared
  # with the two records
  def &(contact_record_2)
    me = dup
    me.details = self.class.shared_contact_details(self,contact_record_2)
    me
  end
  
  # Returns a new contact record that only has the details that existed in 
  # the first contact but not the second contact
  def -(contact_record_2)
    me = dup
    me.details = details - self.class.shared_contact_details(self,contact_record_2)
    me
  end

  # Sometimes we get contacts with blank details
  def remove_blank_contacts
    self.details = details.select { |cd| !cd.value.blank? }
  end
  
  # Try to match this contact number to a user
  # NOTE: this will rematch even if it's already matched
  # matches to an existing user and returns the user
  # Notes:
  #   We don't match on name - just phone number and email
  #   Even if the name is completely different, we keep things as is for now, that is, we don't double-check against
  #     name to see if there was a phone typo.
  # 
  def existing_user_match
    # First see if any of the phones match the "tested" phone (stored in user's profile)
    matching_users = []
    contact_details.each do |cd|
      if cd.is_phone? 
        # Make sure we make the search using the full value b/c that's what we save in the user's mobile number record
        if user = User.find_by_mobile_number(cd.normalized_value)
          cd.update_attribute(:kind,:mobile_phone) unless cd.is_mobile_phone?
          matching_users << user
        end
      elsif cd.is_email?
        # Now let's see if this contact's emails match a verified email in the system
        user = User.find_by_email(cd.email) and matching_users << user
      else
        raise "Contact record has to either be a phone or an email : #{cd.inspect}"
      end
      
      
      # If we haven't found a user to bind to yet based upon confirmed results, 
      # see if we match other contact details which may have already been bound to a user 
      # already.  If so, then we don't make a new user, but just bind to the same existing user.  
      # We consider mobile phones and emails to be unique.  If it's not a unique identifier
      # then we treat them as separate users
      unless user 
        ContactDetail.where({:value => cd.value,:kind => cd.kind}).each do |cd2|
          if cd2.user && (cd.is_unique_identifier? || self.name_matches(cd2.contact_record)) 
            matching_users << cd2.user
          end  
        end
      end      
    end
    # It's very possible to match multiple times because one contact record may have the 
    # email and another a phone number, for example.  
    if matching_users.uniq.length > 1
      # For now just raise an error, later we'll have to deal with it somehow
      logger.warn "OH OH, found multiple matching users #{matching_users.uniq.ids.inspect} for contact record #{id}"
    end
    return matching_users.first
  end

  def name_matches(record)
    first_name == record.first_name && last_name == record.last_name
  end

  def details_info
    details.map(&:kind).join(",")
  end

  def hs
    "[#{id}]#{name} by #{source.hs}: (#{details.map(&:hs)*','})"
  end
end