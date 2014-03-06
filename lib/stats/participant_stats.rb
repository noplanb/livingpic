class ParticipantStats
  
  attr_reader :occasion
  
  def initialize(occasion)
    @occasion = occasion
  end

  def stats
    stats = []
    @occasion.participants.each do |participant|
      stat = {}
      stat[:id] = participant.id
      stat[:name] = participant.name
      stat[:inviters] = Invite.inviters_of_user_for_occasion(participant, @occasion).map(&:fullname)
      stat[:sms] = Notification.in(@occasion).to_u(participant).of_kind(:sms).count.dash_for_0
      stat[:push] = Notification.in(@occasion).to_u(participant).of_kind(:push).count.dash_for_0
      stat[:device] = (participant.device and participant.device.platform)
      stat[:gallery_views] = AppEventStats.new(:occasion_id => @occasion.id, :user_id => participant.id, :page => "gallery").count
      stat[:detail_views] = AppEventStats.new(:occasion_id => @occasion.id, :user_id => participant.id, :page => "pic_detail").count
      stat[:photos] = Photo.at(@occasion).by(participant).count
      stat[:comments] = @occasion.comments.by(participant).count
      stat[:likes] = @occasion.likes.by(participant).count
      stat[:invited_others] = Invite.by(participant).for(@occasion).count.dash_for_0("") 
      stats << stat
    end     
    added_photos = stats.select.select{|s| s[:photos] > 0}.sort{|a,b| b[:photos] <=> a[:photos]}
    no_photos = (stats - added_photos).sort{|a,b| b[:gallery_views] <=> a[:gallery_views]}
    return added_photos + no_photos
  end

end
