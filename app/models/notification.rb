class Notification < ActiveRecord::Base

  # WARNING - it seems that this class doesn't reload when we do a reload! in the console.  Perhaps because there is
  # a rails class called notification?  Seems strange though.  Needs debugging...

  # puts "loading Notification"

  attr_accessible :trigger, :occasion, :contact_detail, :contact_value, :kind, :recipient_id, :recipient, :sender

  attr_accessor :sender
  attr_reader :template

  cattr_accessor :send_enabled

  require 'twilio-rb'
  require 'notification_logging'

  include NotificationLogging

  # user = recipient - we can possibly derive this from contact_detail, but it's not a required field, so we're being redundant
  belongs_to :recipient,:class_name => "User"
  belongs_to :occasion
  belongs_to :contact_detail
  belongs_to :trigger, :polymorphic => true

  include EnumHandler

  # The SMS providers can also provider us with a ticket as to whether the SMS was delivered or not
  define_enum :status, [:new, :sent, :clicked, :failed]
  define_enum :kind, [:sms,:email,:push], :primary => true

  # Commented out because I want to be able to create ad-hoc notifications, although the SMS template right now is based
  # upon triggers
  # validates_presence_of :trigger, :on => :create, :message => "can't be blank"

  # Contact detail can be blank if someone signs up and just gives his mobile number, so isn't part of someone else's contact list
  validates_presence_of :contact_value, :on => :create, :message => "^Either contact_detail or contact_value must be set"
    
  validates_presence_of :recipient_id, :on => :create, :message => "^The notification must have a recipient",
    :if => Proc.new { |record| record.contact_detail.blank? }

  # I can't call this :to because it gets ignored by ActiveRecord::Relation.  Not sure why.
  scope :to_u, lambda { |user| where(:recipient_id => User.normalize_to_id(user)) }
  scope :to_number, lambda { |number| where(:contact_value => number) }
  scope :for, lambda { |type| where(:trigger_type => type) }
  scope :of_kind, lambda { |kind| where(:kind => kind) }
  scope :in, lambda { |occasion| where(:occasion_id => Occasion.normalize_to_id(occasion)) }
  scope :sent, :conditions => ["ext_id IS NOT NULL"]
  scope :since, lambda { |date| where  ["created_on >= ?",date] }

  # prepare the notification and also make sure to set the contact value for easier viewing and also
  # because sometimes we use the user's mobile number in their record rather than a contact value
  before_create do
    prepare
  end

  after_create do
    # always do push notifications because on dev server we don't have other people's push tokens
    transmit if Notification.enabled? || is_push?()
  end

  before_validation do
    fill_missing_params
  end

  after_validation do
    self.hash_code ||= get_hash_code
    self.kind ||= determine_kind
    self.status ||= :new
  end


  # The preferred method for creating the notification object based upon a trigger object. You can pass the following options:
  # :recipient: the notification recipient - else we try to figure it out from the trigger as best as we can
  # :contact_detail: the contact detail to use for the recipient, else we try to figure it out
  # :contact_value: the contact value to use for the recipient, else we try to figure it out
  # NOTE: this can return a nil if we don't find any way to contact the user
  # returns the notification - you need to check if it saved correctly or not
  def self.trigger(occasion, trigger, options={})
    sender = defined?(trigger.creator) ? trigger.creator : nil
    recipient = options[:recipient] || trigger.target

    # sometimes we need not notify the recipient (e.g. preferences, etc)
    return nil unless options[:force] || should_create?(trigger,recipient,occasion)


    # Make our best guess about how to notify the recipient
    # 1) the recipient has a mobile number, so just send an SMS to it
    # 2) we don't have a known mobile number, so we need to guess at one
    # 3) try all his other numbers
    # 4) Try email
    # NOTE: if the recipient has the app and push is enabled, then we should use push, else sms
    notification = create(:occasion => occasion, :trigger => trigger, :recipient_id => recipient.id, :sender => sender)

    # Contact value will be created automatically.  If there is no contact value then we really had no idea on how to 
    # reach this user, so we have to send messages to any phone we can find and hope that one of them reaches the user
    # Note that the original notification was never created b/c of validation constraints
    unless notification.contact_value
      recipient.contact_details.phone.not_bad.uniq_by(&:value).each do |cd|
        # We send a notification to each of the phone numbers and then pray that one answers....
        notification = create(:occasion => occasion, :trigger => trigger, :recipient_id => recipient.id, :sender => sender,
                              :contact_detail => cd, :kind => :sms)
      end
    end
    notification
  end

  def validate
    if recipient && contact_detail
      raise "Recipient must match the contact detail" unless recipient == contact_detail.user
    end
  end

  # Determine if we're going to send an SMS or push notification
  def determine_kind
    mobile_notification_model = recipient.notify_via_push? ? :push : :sms
    if contact_value
      guess_type_email?(contact_value) ? :email : mobile_notification_model
    elsif contact_detail
      contact_detail.is_phone? ? mobile_notification_model : :email
    end
  end

  def determine_recipient
    contact_detail && contact_detail.user
  end

  # If there is no recipient, we try to deterine it from the contact detail
  # We also try to fill in the contact value as best we can.  This is what we'll be sending the message to
  # It'll either come from the user's profile or the contact detail
  def fill_missing_params
    self.recipient ||= determine_recipient
    if contact_value.blank? && contact_detail.blank? && recipient
      # 2013-05-21  FF commented out so we don't guess at a contact detail - we send information to every 
      # number we have for the user
      # self.contact_value = recipient.mobile_number or self.contact_detail = mobile_number_contact_guess
      self.contact_value = recipient.mobile_number 
    end  
    self.contact_value ||= contact_detail.normalized_value if contact_detail
  end

  def get_hash_code
    while Notification.find_by_hash_code(random_hash = NoPlanB::TextUtils.random_string(8) )
      # Keep generating hash codes
    end
    random_hash
  end

  # You can enable and disable notifications with these couple of methods.  Useful when creating dummy data, etc.
  def self.enable!
    @send_enabled = true
  end

  def self.disable!
    @send_enabled = false
  end

  def self.enabled?
    @send_enabled
  end

  def sent?
    !!ext_id  
  end

  # Returns the sender (when it's a user)
  def sender
    trigger && trigger.respond_to?(:creator) ? trigger.creator : User.system_admin
  end

  # Prepare the notification, that is, fill in the template
  # First we need to save the item so we have an ID to use in a click link
  def prepare
    if @template = choose_template(template_id)
      self.template_id = template.identifier
      template.fill(:notification => self)
    end
  end

  def body
    prepare
  end

  # send the notification
  def transmit
    if recipient.opted_out_of_notifications?
      logger.warn "Not sending notification #{id} to user #{recipient.log_info} because preference is none"
      return
    end

    if body 
      if is_sms? 
        begin
          # Only send messages right for the beta users
          twilio = Twilio::SMS.create :to => contact_value, :body => body.to_str, :from => APP_CONFIG[:twilio_sender_number] 
          self.status = :sent
          self.ext_id = twilio.sid 
          self.save
          recipient.contact_attempted! 
          log_notification("Sent notification to #{recipient.hs} for #{trigger.hs}") rescue npb_sms ("Error logging notification #{id}")
        rescue  => e
          logger.error e.message
          log_notification("Error sending #{trigger_type} notification to #{recipient.hs}")
          update_attribute(:status,:failed)
          # Mark the contact detail as being unreachable
          if contact_detail then contact_detail.update_attribute(:status,:unreachable); end

          npb_sms("Error sending #{trigger_type} SMS notification to #{recipient.hs}")
          false
        end
      elsif is_push?
        unviewed = recipient.num_unviewed_notifications
        response = PushNotification.new.notify_devices(
          :content => body, 
          # :android_header => body,
          :devices => [recipient.push_token], 
          :ios_badges => unviewed,
          :data => {:c => id})
        if response
          update_attribute(:ext_id,response["response"]["Messages"].first)
        else
          npb_email("Error sending #{trigger_type} push notification to #{recipient.hs}")
        end
      else
        # Send an email here
      end
    else
      logger.warn "Notification ID #{id} has no body so can't transmit it"
    end
  end

  # Return what social action triggered this notification
  def social_action
    trigger && trigger.class.name.downcase.to_sym
  end

  def hs
    "Notification [#{id}] for #{trigger.hs}"    
  end

  # Print a shorter version of notification info
  def hs_s
    "[#{id}] for #{trigger.class.name} #{trigger.id}"
  end

  private

  # This returns a template to be used for the notification
  # You can pass in an ID, of the form, for example, invite.2, meaning v2 of the invite template
  def choose_template(template_id=nil)
    template_type = case kind
    when :sms then SmsTemplate
    when :push then PushTemplate
    else
    end
    if template_id
      type,id = template_id.split('.')
      template_type[type.to_sym,id]
    else
      case trigger
      when Invite
        recipient.is_initialized? ? template_type[:invite_non_active] : template_type[:invite]
      when PhotoTagging
        template_type[:photo_tagging]
      when Photo
        template_type[:photo]
      when Occasion
        template_type[:occasion]
      when Comment
        template_type[:comment]
      when Like
        template_type[:like]
      else
        nil
      end
    end
  end

  # Let's guess if this is an email (very simple method)
  def guess_type_email?(value)
    value.match(/\S+@\S+/)
  end

  # Get the last notification for a photo or comment to the user
  def self.last_for_added_content(user)
    Notification.for(["Photo","Comment","Like"]).to_u(user).last 
  end


  # I guess the logic here depends on what we send for phototagging and the user's preferences (TBD)
  def self.should_create?(trigger,user,occasion,time_between_notifications=nil)
    # GARF - this should be to a number, not to the user
    unless Invite === trigger 
      return false if !user.is_active? and user.notifications.count >= APP_CONFIG[:max_notifications_for_inactive_users]
    end

    time_between_notifications ||= APP_CONFIG[:min_time_between_notifications_in_minutes]
    case trigger
    when Invite
      occasion.last_viewed_by(user).nil?
    # Changed so that they allways go out for comments but not photos. Lets err on the side of over notifying then turn it down if 
    # we find it annoying. Needs to be smarter eventually. Always send to others on the thread or the person who took the photo. Etc.
    when Photo
      # Only send notifications for a new photo if we haven't sent one in some time period
      (n = last_for_added_content(user)).nil?  || (Time.now - n.created_on >  time_between_notifications * 60)
    when Comment
      return true if trigger.thread_participants.include? user
      return true if trigger.photo.creator == user
      return false
      # (n = last_for_added_content(user)).nil?  || (Time.now - n.created_on >  time_between_notifications * 60)
    when Like
      # Only send a like to the taker of the photo
      trigger.photo.creator == user
    else
      true
    end
  end
    
  def mobile_number_contact_guess
    return nil unless recipient
    (sender && sender.mobile_number_contact_for(recipient)) || (recipient.mobile_number_contact_guess)
  end

  enable! if APP_CONFIG[:send_notifications]
  
end
