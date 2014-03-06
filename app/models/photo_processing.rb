require "resque"
require 'quick_magick'

module PhotoProcessing
  
  
  module CreateThumbs
    @queue = :create_thumbs
    THUMB_SIZE = 75
  
    def self.perform
      sleep 1
      puts "Created a thumbnail!"
    end
    
    
    def self.create_thumb_for_photo2
      
      full_dir = "#{Rails.root}/public/photos/test"
      file_paths = Dir.glob("#{full_dir}/*")
      
      file_paths.each do |p|
        i = QuickMagick::Image.read(p).first
      
        # Make square thumbnail.
        # First shrink the smaller dimension to the size of the thumbnail.
      
        w =  i.width
        h =  i.height
        
        if w < h
          i.resize "#{THUMB_SIZE}x"
          i.crop "-gravity center #{THUMB_SIZE}x#{THUMB_SIZE}+0+0"
        else
          i.resize "x#{THUMB_SIZE}"
          i.crop "-gravity center #{THUMB_SIZE}x#{THUMB_SIZE}+0+0"
        end
        
        
        name = File.basename(i.image_filename, ".JPG")
        
        i.save "#{full_dir}/#{name}_thumb.jpg"
      end
      
      
    end
    
    def self.add_to_queue
      Resque.enqueue(Createthumbs)
    end
  end
  
  
  
end
