# Thoughts:
# We may just want to split this into emails and phone numbers, because there's so little
# that's shared between them (user_id, and a couple of statuses).

class ContactDetail < ActiveRecord::Base
  attr_accessible :field_name, :field_value
  
  belongs_to :contact_record
  
  delegate :user, :source, :to => :contact_record, :allow_nil => true

  validates_presence_of :value, :on => :create, :message => "can't be blank"
  
  include EnumHandler
  include PhoneHandling
  
  # We mark these as unknown unless we have determined what kind they are
  # We set other_phone if we try to message a mobile phone and it comes back as a fail
  # Phones are set to unknown phone in the beginning
  define_enum :kind, [:mobile_phone,:email,:other_phone,:unknown_phone], :sets => {:phone => [:mobile_phone,:other_phone,:unknown_phone], :unique_identifier => [:email,:mobile_phone] }, :primary => true
  
  # Kind of a jumbled set of statuses.  Pending means that we have sent it out and don't know if the user 
  # has clicked on it or not (we should be able to tell based upon the notifications but use pending to eliminate a join)
  define_enum :status, [:unknown, :pending, :opened, :clicked, :service_confirmed, :user_confirmed, :unreachable], 
    :sets => {:confirmed => [:clicked,:opened,:service_confirmed,:user_confirmed], :bad => [:unreachable] }, :primary => true
  
  scope :international, :conditions => ["country_code != ?",PhoneHandling.default_country_code]

  MOBILE_PHONE_MONIKERS = %w(iphone mobile cell)
  OTHER_PHONE_MONIKERS = %w(home work)
  
  validates_presence_of :value, :on => :create, :message => "can't be blank"
  
  before_save do
    # Normalize the phone number to get rid of the () and spaces and - values, and if there is a +1, remove that as well
    setup_phone
    cleanup
  end

  after_initialize do
    determine_kind
    setup_email
    setup_phone 
    self.status ||= :unknown
  end

  def phone
    is_phone? ? value : nil
  end
  
  def email
    is_phone? ? nil : value    
  end
  
  # We don't want to anyone else to set the kind and value attributes
  # These are set automatically by this object based upon the field value and field name
  # Note that :kind= is already defined in the 
  private :kind=
  
  def value=(val)
    write_attribute(:value,val)
  end
  private :value=
  
  def normalized_value
    is_phone? ? normalize_phone_number(value,country_code) : value
  end

  # Clean up the contact record
  # If the record does not have the required 10 digits, 
  # we put in the inviter's area code
  def cleanup
    self.value.strip!
    if is_phone? && get_area_code(value).blank? && !international? 
      self.value = add_area_code(get_area_code(source.mobile_number),value)
    end
  end
  
  def international?
    (country_code && self.country_code.to_s != PhoneHandling.default_country_code.to_s) or is_international?(value)
  end

  def determine_kind
    if (kind.blank? || kind == :unknown_phone)&& !field_value.blank?
      if guess_type_email?
        self.kind = :email 
      else
        self.kind = MOBILE_PHONE_MONIKERS.include?((field_name || "").downcase) ? :mobile_phone : 
          OTHER_PHONE_MONIKERS.include?((field_name || "").downcase) ? :other_phone : :unknown_phone 
      end
    end     
  end
  
  def setup_email
    self.value = field_value if is_email?
  end
  
  # We save the contact detail phone number w/o the country code or the dialing + prefix
  # So number being saved is something like 2126668989, not +12126668989
  def setup_phone
    if is_phone? && value.blank?
      code,number = strip_country_code(field_value)
      self.country_code = code 
      self.value = number
    end
  end
  
  # Let's guess if this is an email (very simple method)
  def guess_type_email?
    field_value.match(/@/)
  end
  
  def mobile_numbers_for(user)
    user_id = User === user ? user.id : user
    ContactDetail.mobile_phone.not_unreachable.where(:user_id => user_id,:kind => :mobile_phone)
  end

  def matches?(cd)
    value == cd.value && kind == cd.kind
  end
  
  # a less stringent matching condition
  def somewhat_matches?(cd)
    value == cd.value
  end
  
  # Update a contact detail if it necessary
  # Presumably we have established that this detail is exactly or roughly the same as one we already have
  # at a minimum the values should match
  # For example, a number may have been registered as :work, but then is changed to :home or :mobile
  # Same for emails
  # returns a list of updated fields
  # NOTE: Ignores :status, :contact_record_id
  def update_if_necessary(cd2)
    updated = []
    if value == cd2.value
      self.kind = cd2.kind and updated << :kind if kind != cd2.kind
      self.field_value = cd2.field_value and updated << :field_value if field_value != cd2.field_value
      self.field_name = cd2.field_name and updated << :field_name if field_name != cd2.field_name
      save! unless new_record? 
    end
    updated
  end

  def country
    is_phone? && PhoneHandling.country_from_code(country_code)
  end

  # print human-readable information
  def hs
    "[#{id}]#{kind}: #{value}"
  end

end
