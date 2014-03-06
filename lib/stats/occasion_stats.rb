class OccasionStats
  
  attr_reader :occasions
  
  def initialize(occasions)
    @occasions = occasions
  end

  def stats
    stats = []
    @occasions.each do |occasion|
      stat = {}
      stat[:id] = occasion.id
      stat[:creator] = occasion.user.fullname
      stat[:num_photos] = occasion.photos.count
      stat[:name] = occasion.name
      stat[:num_participants] = occasion.participants.length
      stat[:percent_added_photos] = 100 * occasion.participants.select{|p| Photo.at(occasion).by(p).count > 0}.length / stat[:num_participants]
      stat[:percent_viewed_gallery] = 100 * occasion.participants.select{|p| AppEventStats.new(:occasion_id => occasion.id, :user_id => p.id, :page => "gallery").count > 0}.length / stat[:num_participants]
      stat[:photos_per_participant] = occasion.photos.count / stat[:num_participants]
      stat[:gallery_views_per_participant] = AppEventStats.new(:occasion_id => occasion.id, :page => "gallery").count / stat[:num_participants]
      stat[:photo_views_per_participant] = AppEventStats.new(:occasion_id => occasion.id, :page => "pic_detail").count / stat[:num_participants]
      stat[:comments_per_participant] = occasion.comments.count / stat[:num_participants]
      stat[:likes_per_participant] = occasion.likes.count / stat[:num_participants]
      stats << stat
    end
    stats
  end

end