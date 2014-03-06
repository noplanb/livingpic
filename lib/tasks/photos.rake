namespace :photos do
  desc "Destroy all photos and import them from public/system/photos/raw_test_pics creating thumbnails along the way."
  task :import => :environment do
    require 'paperclip'
    
    Photo.destroy_all
    FileUtils.rm_rf File.join(Rails.root, "public", "system", "pics", "*")
    raw_dir = "#{Rails.root}/public/system/photos/raw_test_pics"
    
    puts "Importing photos from: #{raw_dir}"
    
    Dir.glob("#{raw_dir}/*").last(300).each do |raw_path|
      puts "here"
      puts raw_path
      tf = Tempfile.open([File.basename(raw_path, File.extname(raw_path)), File.extname(raw_path)])
      tf.write File.open(raw_path, "r"){|f| f.read }
      uf = ActionDispatch::Http::UploadedFile.new( {:filename => File.basename(raw_path), :type => "image/jpeg", :tempfile => tf } )
      p = Photo.new(:pic => uf,:test_seed => true)
      p.save_with_aspect_ratio
      p.pic.reprocess!(:phone)
      puts p.inspect
    end
    
  end
  
  task :add_all_to_occasion => :environment do
    occ = Occasion.last
    Photo.all.each do |p|
      p.update_attribute(:occasion_id, occ.id)
    end
  end
  
  task :add_user_to_all_photos => :environment do
    Photo.all.each do |p|
      p.update_attribute(:user, User.last)
    end
  end  
end
