class PhotosController < ApplicationController
  
  require 'thread'
  protect_from_forgery :except => [:create,:dummy,:like,:comment,:test]
  before_filter :normalize_state_variables, :only => [:create]

  before_filter :requires_current_user, :except => [:test]

  # Create the photo
  # NOTE that we double-check to make sure that the photo doesn't exist already because of network errors, we may already have
  # saved the photo
  def create
    # raise "Error"
    if user_id = current_user_id
      occasion = Occasion.find params[:occasion_id]
      app_info = params[:app_info]    
      pic = app_info[:is_running_in_browser] ?  generate_test_pic(occasion, params[:tmp_file_uri]) : params[:file] 
      pic.original_filename.gsub!(/[=&?]/,'_')
      if pic.original_filename && p = Photo.where(:user_id => user_id, :occasion_id => occasion.id, :pic_file_name => pic.original_filename).first
        logger.warn "Photo #{pic.original_filename} in occasion #{occasion.id} already exists in photo #{p.id} so not creating it"
        # I send the same one back to the client with a flag indicating that it's a duplicate, and leave it to the client to deal with it
        render :json => p.attributes_for_app.merge(duplicate: true)
      else 
        p = Photo.new({:user_id => user_id, :occasion_id => occasion.id, :pic => pic, :time => DateTime.parse(params[:time]), 
            :latitude => params[:latitude], :longitude => params[:longitude], :caption => params[:caption]})
        
        p.save_with_aspect_ratio
        
        # FF - this now done in the model.
        # TODO - here start a new thread to reprocess the photo - basically creating the styles that we want because 
        # we don't want to save the styles during the original upload
        # Thread.new do 
        #   begin
        #     time = Time.now
        #     logger.info "Processing thumb and phone version for pic #{p.id}"
        #     p.pic.reprocess!(:thumb,:phone)
        #     p.all_processing_done
        #     logger.info "Photo processing done in #{Time.now-time}s"
        #   rescue  => e
        #     logger.error "Error processing phone version of pic #{p.id} with error #{e}"
        #   end
        # end
        render :json => p.attributes_for_app
      end

    else
      # GARF - this should be an error to tell the app to checkin again
      render :text => "NOK"
    end
  end
  
  def test_scroll
    render :json => Photo.first(200).map{|p| p.pic.url(:phone)}
  end
  
  # Return the information associated with a single photo
  def get
    photo = Photo.find_by_id(params[:id])
    if photo && current_user && current_user.has_access_to_occasion?(photo.occasion_id)
      render :json => photo.attributes_for_app 
    else
      render :json => {}
    end
  end

  # current user likes a photo
  # returns the total number of likes
  def like
    photo = Photo.find(params[:id])
    photo.likes << Like.new(:user_id => current_user_id)    
    render :json => photo.likes.map(&:liker_attributes_for_app)
  end

  # Return the count of likes 
  def likes
    render :json => Photo.find(params[:id]).likes.count
  end

  # This should be a post
  def comment
    photo = Photo.find(params[:id])
    photo.comments << Comment.new(:user_id => current_user_id, :body => params[:body])  
    render :json => photo.comments.map(&:attributes_for_app)
  end

  # Retrieve the comments for a particular photo as a json object
  def comments
    render :json => Photo.find(params[:id]).comments.map(&:attributes_for_app)
  end

  # GARF!!! This is used to get around a bug in android where it fails to upload a file that has just been snapped the first time.
  # The work around for now is to try to upload it twice once to dummy her the to create above.
  # Need to get to the bottom of this bug when we have time.
  # GARF - may not be needed anymore
  def dummy
    render :text => "ok"
  end
  
  # Used for dev of p_gallery can be removed when that dev project is finished.
  def all
    render :json => Photo.all.map{|p| p.pic.url(:thumb_r)}
  end
  
  # This method is used to pass to the client photos with all possible orientations in order to test display esp with the zoomer.
  # Requirements:
  #   - test photos under assets/images/test_orientation
  #   - ImageMagick 
  def test_orientation_json
    # Copy the test_photos over to the public folder.
    test_photos_source_dir = File.join [Rails.root, "app", "assets", "images", "test_orientation"]
    test_photos_target_dir = File.join [Rails.root, "public", "system", "photos"]
    test_dir = File.join [test_photos_target_dir, "test_orientation"]
    FileUtils.rm_rf(test_dir) if File.exist? test_dir
    FileUtils.cp_r(test_photos_source_dir, test_photos_target_dir)
    Dir.chdir test_dir
    
    photos_array = []
    
    Dir.glob("**").reverse.each do |p_dir|
      Dir.glob("#{p_dir}/*").each do |p_file|
        photo = {}
        photo[:url] = File.join ["/system/photos/test_orientation", p_file]
        photo_file = File.join [test_dir, p_file]
        photo[:orientation] = (`identify -format %[exif:Orientation] #{photo_file}`).to_i
        photo[:width] = (`identify -format %[exif:ExifImageWidth] #{photo_file}`).to_i
        photo[:height] = (`identify -format %[exif:ExifImageLength] #{photo_file}`).to_i
        photo[:name] = p_file
        photos_array << photo
      end
    end
    render :json => photos_array
  end
  
  private
    
  def generate_test_pic(occasion, tmp_file_uri)
    user_id = current_user_id
    pic_num = occasion.photos.count + 1
    pic_file = File.join(Rails.root, "tmp", "brw_#{occasion.id}_#{pic_num}.jpg")
    
    if tmp_file_uri.match /^http[s]*:/
      system "curl -o #{pic_file} #{tmp_file_uri}"
    else
      lbl = "'\nPic[#{pic_num}]\nUser[#{user_id}]\nOccasion[#{occasion.id}]\n'"
      unless system "convert -background navy -fill white -pointsize 60 -size 500x400 -gravity center label:#{lbl} #{pic_file}"
        raise "Please install Imagemagic on your system and make sure the system command 'convert' works."
      end 
    end
    
    tf = Tempfile.open([File.basename(pic_file, File.extname(pic_file)), File.extname(pic_file)])
    tf.write File.open(pic_file, "r"){|f| f.read }
    uf = ActionDispatch::Http::UploadedFile.new( {:filename => File.basename(pic_file), :type => "image/jpeg", :tempfile => tf } )
    uf
  end
    
end
