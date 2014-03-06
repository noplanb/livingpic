class Participation < ActiveRecord::Base

  attr_accessible :user_id,:occasion_id, :indication
  belongs_to :occasion
  belongs_to :user
  belongs_to :indication, :polymorphic => true

  validates_presence_of :occasion_id, :on => :create, :message => "can't be blank"
  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :occasion_id, :scope => [:user_id,:indication_type, :indication_id], :on => :create, :message => "must be unique"

  include EnumHandler
  define_enum :kind, [:inviter, :invitee, :tagger, :taggee, :occasion_creator, :photo_taker, :commenter, :liker], 
    :sets => {:active => [:inviter,:tagger,:occasion_creator], :content_creation => [:photo_taker, :commenter, :liker]}, :primary => true

  scope :by, lambda { |user| where(:user_id => User.normalize_to_id(user)) }  
  scope :in, lambda { |occasion| where(:occasion_id => Occasion.normalize_to_id(occasion)) }

  # These determine the order in which we present things.  lower is better, that is, presented 
  # sooner
  # TODO - adjust these priorities
  PRIORITIES = {
    :occasion_creator => 4,
    :tagger => 2,
    :taggee => 3,
    :inviter => 2,
    :invitee => 1,
    :photo_taker => 1,
    :commenter => 2,
    :liker => 2,
  }

  def self.find_or_create!(attributes)
    unless p = Participation.where(attributes).first 
      p = Participation.new(attributes)  
      # update_attribute separately b/c we want :kind to be internally assigned (so it can't be mass assigned)
      p.kind = determine_kind(attributes)
      p.save!
    end
    p
  end

  def self.determine_kind(attributes)
    if indication = attributes[:indication] and attributes[:user_id]
      case indication
      when Invite
        attributes[:user_id] == indication.inviter_id ? :inviter : :invitee
      when Photo
        :photo_taker
      when Occasion
        :occasion_creator
      when PhotoTagging
        attributes[:user_id] == indication.tagger_id ? :tagger : :taggee
      when Like
        :liker
      when Comment
        :commenter
      else
        raise "Don't recognize the kind of participation"
      end
    end
  end

  # Indicate the occasions of interest for the user, sorted by the strength of participation
  def self.prioritized_occasions_for_user(user)
    user_id = User.normalize_to_id(user)
    by(user_id).inject({}) { |wo,p| 
      wo[p.occasion_id] += PRIORITIES[p.kind]
    }.sort_by{ |k,v| v}.column(0)
  end

  def self.kind_abbreviation(kind)
    {:inviter => "I", :invitee => "It", :tagger => "PT" , :taggee => "Pt", :occasion_creator => "C", :photo_taker => "P"}[kind]
  end

  def kind_abbrev
    self.class.kind_abbreviation(kind)
  end

  def hs
    "Participation [#{id}] by #{user.hs} as #{kind} in #{occasion.hs}"
  end
end
