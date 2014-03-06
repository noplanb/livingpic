namespace :photos do
  require 'paperclip'
  
  require File.join(Rails.root,'config','initializers','load_config')

  class S3Photo

    # This is a mega-hack to copy the local photos to S3
    include ActiveSupport::Callbacks
    include ActiveModel::Validations
    include Paperclip::Glue

    attr_accessor :pic_file_name, :pic_file_size, :pic_updated_at, :pic_content_type
    class << self
      def after_save(&block) ; end

      def before_destroy(&block); end

      def after_destroy(&block); end

    end

    attr_reader :id
    paperclip_extra_options = {
      storage: :s3,
      s3_credentials: "#{Rails.root}/config/s3.yml",
      path: "/photos/:attachment/:id_partition/:style/:filename",
      s3_permissions: :public_read,
      bucket: APP_CONFIG[:s3_bucket]
    }
    has_attached_file :pic, {:styles => { :phone => "960x960>", :thumb => "200" } ,:post_processing => false}.merge(paperclip_extra_options)

    def initialize(photo)
      @id = photo.id
      self.pic = photo.pic
    end
   
    def save
      pic.save
    end

  end

  desc "Synchronize the local images to S3"
  task :sync_to_s3,[:first,:last] => :environment do |t, args|
    puts "Synchronizing photos to s3 bucket #{APP_CONFIG[:s3_bucket]}"
    if APP_CONFIG[:use_s3]
      puts "Please re-run after setting config parameter :use_s3 to false"
      exit
    end

    first = args[:first].or_if_blank  Photo.first.id
    last = args[:last].or_if_blank Photo.last.id

    puts "Pushing photo IDs #{first} to #{last} to S3"
    (first.to_i..last.to_i).each do |id|
      photo = Photo.find_by_id(id) or next
      # If this photo object has a picture, we synchronize the original photo 
      # On a local system, the offset for this pic should be 
      if photo.pic.exists?
        sp = S3Photo.new(photo)
        puts "Moving photo #{photo.id} to S3"
        sp.save
      else
        puts "Photo #{photo.id} doesn't have a pic file"
      end
    end
  end

end