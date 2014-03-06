namespace :cache_stats do
  
  task :cache_all => :environment do
    occasion_stats = OccasionStats.new(Occasion.select{|o| o.participants.length > 3}).stats
    SimpleCache.new.store(occasion_stats, "occasions")
    
    occasion_stats.each do |stat|
      cache_participants(Occasion.find(stat[:id]))
    end
  end
  
  def cache_participants(occasion)
    puts "Storing participant stats for occasion #{occasion.id}"
    participant_stats = ParticipantStats.new(occasion).stats
    SimpleCache.new.store(participant_stats, "participants_for_occ_#{occasion.id}")
  end
  
end
