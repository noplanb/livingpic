module Admin
  class StatsController < AdminController
    
    layout "admin_desktop"
    
    # This stats controller diplays stats for occasions and participants that have been previously cached using "rake cache_stats:cache_all"
    # This rake caches the statistics using simple cache so that they can be displayed rapidly. 
    # Pages would load far too slowly if statistics were queried realtime.
    
    def occasions
      @stats = SimpleCache.new.fetch("occasions")
      render :template => "admin/stats/occasions"
    end
    
    def participants
      @occasion = Occasion.find(params[:occasion_id])
      @stats = SimpleCache.new.fetch("participants_for_occ_#{params[:occasion_id]}")
      render :template => "admin/stats/participants"
    end
    
    # Get all the photo data off sanis android for investigation purposes.
    def post_photo_data
      save_photo_data("sani_android_photo")
    end
    
    def post_all_photos_data
      save_photo_data("sani_android_photos")
    end
    
    # Get all the thumbs data off sanis android for investigation purposes.
    def post_thumb_data
      save_photo_data("sani_android_thumbs")
    end
    
    def save_photo_data(target_file)
      path = File.join(Rails.root, "lib", "album_data", target_file)
      f = File.open(path,"w")
      f.puts params[:data]
      f.close
      render :text  => "ok"
    end
    
    # Shows the Android data for all native photos on sanis Android. Used for testing.
    def photos_data
      path = File.join(Rails.root, "lib", "album_data", "sani_android_photos")
      @json = "empty"
      f = File.open(path, "r") do |f|
        @json = f.read()
      end
      @photos = JSON.parse @json
      @pretty_photos = JSON.pretty_generate @photos
      @buckets = {}
      @photos.each do |p|
        @buckets[p["bucket_display_name"]] ||= []
        @buckets[p["bucket_display_name"]] << p
      end
      render :template => "admin/stats/photos_data"
    end
    
    def samsung_photos_data
      path = File.join(Rails.root, "lib", "album_data", "sani_samsung_photos")
      @json = "empty"
      f = File.open(path, "r") do |f|
        @json = f.read()
      end
      @photos = JSON.parse @json
      @photos.sort!{|a,b| b["_id"].to_i <=> a["_id"].to_i}
      render :template => "admin/stats/samsung_photos_data"
    end
    
    def photo_data
      path = File.join(Rails.root, "lib", "album_data", "sani_android_photo")
      @json = "empty"
      f = File.open(path, "r") do |f|
        @json = f.read()
      end
      @photos = JSON.parse @json
      @pretty_photos = JSON.pretty_generate @photos
      render :template => "admin/stats/photo_data"
    end
    
    def thumb_data
      path = File.join(Rails.root, "lib", "album_data", "sani_android_thumbs")
      @json = "empty"
      f = File.open(path, "r") do |f|
        @json = f.read()
      end
      @photos = JSON.parse @json
      @pretty_photos = JSON.pretty_generate @photos
      render :template => "admin/stats/thumb_data"
    end
    
  end
end