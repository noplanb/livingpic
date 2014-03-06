namespace :app do
  require 'open-uri'
  require File.join(Rails.root,'config','initializers','load_config')

  require 'version'
  
  # The VERSION_CODE needs to be incremented for every successive release to the android store.
  # They are reflected in the AndroidManifest.xml
  ANDROID_RELEASE_VERSION_CODE = APP_CONFIG[:android_version_code]
  ANDROID_RELEASE_VERSION_NAME = APP_CONFIG[:app_version]
  BUILD_NUMBER = `svn info #{Rails.root}` =~ /Revision: (\d+)/ && $1

  # 2013-11-04: new directory structure
  # In APP_DIR, we have ios and android
  # First time through, run 'rake setup_android' or 'rake setup_ios'
  # NOTE: make sure the cordova frameworks directory is correct

  APP_NAME = "#{APP_CONFIG[:site_name]}"
  APP_SIGNATURE = "com.noplanbees.#{APP_NAME.downcase}"

  APP_DIR = File.expand_path File.join(Rails.root,'../','app')
  APP_DIR_IOS = File.join(APP_DIR,"platforms","ios")
  APP_DIR_IOS_PROJECT = File.join(APP_DIR_IOS,APP_NAME)
  APP_DIR_ANDROID = File.join(APP_DIR, "platforms", "android")
  KEYSTORE_DIR_ANDROID = File.join(Rails.root, "../", "android_keys")
  
  SOURCE_ASSETS_DIR = File.join(APP_DIR,'assets')
  COMPILED_ASSETS_DIR = File.join(Rails.root,'public','assets')

  ANDROID_PUSH_WOOSH = true
  ANDROID_PUSHWOOSH_USE_SOURCE = false
  
  # NOTE: This MUST have n.n floating point format - don't do something like 1.0.1 because it's used in version comparisons.  Even if there is just a minor
  # bug fix, just role the minor version number
  version = Version.current.v

  task :version_android       do |t|; puts ENV['DEVICE_RELEASE_VERSION'] = "android_d.#{version}"; end
  task :version_android_store do |t|; puts ENV['DEVICE_RELEASE_VERSION'] = "android_store_d.#{version}"; end
  task :version_android_release do |t|; puts ENV['DEVICE_RELEASE_VERSION'] = "android_release_d.#{version}"; end
  task :version_iphone        do |t|; puts ENV['DEVICE_RELEASE_VERSION'] = "iphone_d.#{version}"; end
  task :version_iphone_store  do |t|; puts ENV['DEVICE_RELEASE_VERSION'] = "iphone_store_d.#{version}"; end
  
  task :build_android =>         [:version_android,       :do_build_android]
  task :stage_android =>    [:version_android,       :precompile_and_stage_android]
  task :build_android_store =>   [:version_android_store, :do_build_android]
  task :build_android_release => [:version_android_release, :do_build_android_release]
  task :build_ios =>           [:version_iphone,        :do_build_ios]
  task :build_ios_store =>     [:version_iphone_store,  :do_build_ios]
  
  def release_version?
    ENV['DEVICE_RELEASE_VERSION'].match /release/
  end

 desc "Precompile and stage only"
 task :precompile_and_stage_android => [ 
                                         :precompile, 
                                         :render_html, 
                                         :stage_common_files,
                                         :set_android_version,
                                         :clean_up
                                       ] do
   puts "Precompile and stage complete"
 end
 
 desc "Build for android."
  task :do_build_android => [
                             :setup_for_android,
                             :precompile_and_stage_android,
                             :stage_weinre_js,
                             :set_manifest_debuggable,
                             :deploy_android, 
                             ] do 
    puts "Android build done."
  end  
  
  desc "Build android release version."
  task :do_build_android_release => [
                                     :setup_android,
                                     :precompile_and_stage_android,
                                     :set_manifest_not_debuggable,
                                     :deploy_android_release, 
                                     ] do 
    puts "Android build release done."
  end  
  
  
  desc "Build for xcode"
  task :do_build_ios => [
                           :setup_for_ios,
                           :set_ios_version,
                           :precompile, 
                           :render_html, 
                           :stage_common_files, 
                           :clean_up
                          ] do
    puts "Xcode build done at #{Time.now}"
  end
        

    
  ##################
  #  ONE-TIME ENVIRONMENT SETUP
  ##################

  # Target directory structure is to have a symbolic link named "app" that points to the build of choice
  # Then we have directories that have the app name and are timestamped, for ex, LivingPic.23434445
  # This will be the standard directory created by cordova, and in it we will have
  # two directories of interest: platforms and plugins.
  # When we add plugins, we add them to all the platforms

  # *************
  # CORDOVA
  # *************

  task :backup_cordova_project do
    extension = Time.now.to_i
    app_dir = File.symlink?( APP_DIR )? File.readlink(APP_DIR) : APP_DIR
    dir = File.expand_path File.dirname( APP_DIR)
    # File.readlink doesn't return the directory...
    app_dir = File.join(dir,File.basename(app_dir))
    puts "APP_DIR = #{APP_DIR}, app_dir = #{app_dir}"
    backup_name = File.join(dir,"#{APP_NAME}.#{extension}")
    puts "Renaming #{app_dir} to #{backup_name}"
    File.rename app_dir, backup_name
  end

  # Assumption: CLI cordova has been loaded via sudo npm install -g cordova 
  # NOTE: Make sure you have a fairly recent release of node
  desc "Setup ios by creating a new project via the command line routines"
  task :create_cordova_project do
    app_dir = File.join File.dirname(APP_DIR),APP_NAME
    if File.exist? app_dir
      raise "ERROR: cordova project #{app_dir} already exists. Either delete it or do a backup using rake app:backup_cordova_project"
    end
    system "cordova create #{app_dir} #{APP_SIGNATURE} #{APP_NAME}"

    # If app was a symbolic link, then re-establish it for the just-created directory....
    if File.symlink? APP_DIR
      File.delete APP_DIR
    elsif File.exist? APP_DIR
      puts "ERROR: there is already a file called #{File.basename(APP_DIR)}.  Renaming it so I can make a symlink to the new directory"
      File.rename APP_DIR,"#{APP_DIR}.#{Time.now}"
    end
    puts "Creating a new symlink named #{APP_DIR} to our real app directory #{app_dir}"
    File.symlink(app_dir,APP_DIR)

    Dir.chdir app_dir
    system "cordova platform add ios"
    system "cordova -d platform add android"

    #  Plugin versions below set to the versions we used in our mid jan store release.
    ["device@0.2.6","network-information@0.2.6","geolocation@0.3.5","camera@0.2.6","file@0.2.5","file-transfer@0.4.0","contacts@0.2.7","console@0.2.6","inappbrowser@0.3.0"].each do |plugin|
      system "cordova plugin add org.apache.cordova.#{plugin}"
    end
    
    # Now add third party plugins that support new plugin architecture 
    # those that are platform-specific will be added in platform-specific implementations)
    system "cordova plugin add https://github.com/shaders/pushwoosh-phonegap-3.0-plugin.git"

    # This is only for android - it doesn't install in ios
    system "cordova plugin add https://github.com/chrisekelley/cordova-webintent.git"

    # Now build the projects
    system "cordova build ios"
    system "cordova build android"

    # now remove some of the crap that cordova leaves around
    # FileUtils.rm_rf(File.join(APP_DIR,"www"))
    [asset_dir_ios,asset_dir_android].each do |dir|
      Dir.chdir dir
      File.delete "config.xml" if File.exist? "config.xml"
      File.delete "js/index.js" if File.exist? "js/index.js"
      Dir.glob("cordova-app-hello-world*").each do |dir|
        FileUtils.rm_rf(dir)
      end
    end

    puts <<-END

    *******************
    Created the android and ios projects.  
    Now you can run
      >rake app:setup_ios or rake app:setup_android
    followed by 
      >rake app:build_ios or rake app:build_android
    *******************
    END

  end
  
  
  # ***************
  # = Android & IOS
  # ***************
  desc "Precompile JS and CSS assets"
  task :precompile => :environment do
    Dir.chdir(Rails.root)
    puts "DEBUG=" + (ENV["DEBUG"] || "false")
    # precompile the assets
    ENV['RAILS_ENV'] = 'development'
    ENV['PRECOMPILE_TARGET'] = 'device'
    Rake::Task["assets:precompile"].execute
  end
  
  # Platform-independent creation of index.html file
  task :render_html do
    target_index = File.join(@target_assets_base_dir,"index.html")
    puts "Creating #{target_index} for device type #{@device}"
    ENV['PRECOMPILE_TARGET'] = 'device'
    url = "http://localhost:3000/app/build_page?device_type=#{@device}&device_release_version=#{ENV['DEVICE_RELEASE_VERSION']}"
    puts "Creating the app html index file in #{target_index} from #{url}"
    File.open(target_index,"w") do |f|
      f.write open(url).read
    end 
  end
  
  desc "Stage our app files into www and the android platform."
  task :stage_common_files => [:stage_js, :stage_css, :stage_img]

  def asset_dir_ios(asset_type="")
    t=File.join(APP_DIR_IOS,"www",asset_type)
    Dir.mkdir t unless Dir.exists? t
    t
  end
  
  def asset_dir_android(asset_type="")
    t=File.join(APP_DIR_ANDROID, "assets", "www", asset_type)
    Dir.mkdir t unless Dir.exists? t
    t
  end

  # Platform-independent directory for the assets
  def asset_dir(asset_type="")
    t = File.join(@target_assets_base_dir,asset_type)
    Dir.mkdir t unless Dir.exists? t
    t
  end

  task :stage_js do
    target_dir = asset_dir("js")
    puts "Staging js to #{target_dir}"
    source = File.join(COMPILED_ASSETS_DIR,"application.js")
    FileUtils.cp(source,target_dir)
  end
  
  task :stage_weinre_js do
    if release_version? 
      puts "  ** NOT staging weinre in a release version"
    else
      target_dir = asset_dir("js")
      puts "Staging weinre.js to #{target_dir}"
      source = File.join(Rails.root,"app","assets","javascripts","app_package","weinre","weinre.js")
      FileUtils.cp(source, target_dir)
    end
  end
    
  task :stage_css do
    puts "Staging css"
    source = File.join(COMPILED_ASSETS_DIR,"application.css")
    target_dir = asset_dir("css")
    FileUtils.cp(source,target_dir)
  end
  
  task :stage_img do 
    source_dir = File.join(COMPILED_ASSETS_DIR,"img")
    FileUtils.rm_rf(asset_dir("img"))
    
    puts "Staging img"
    FileUtils.cp_r(source_dir,asset_dir(""))
    
    # Put all the on onboard images in both www/img and www/css/img. See doc/sani/package_app.txt for reason.
    puts "Staging css/img"
    FileUtils.rm_rf(File.join(asset_dir("css"),"img"))
    FileUtils.cp_r(source_dir,asset_dir("css"))
  end
    
  desc "Clean up. Delete the public/assets"
  task :clean_up do 
    puts "Cleaning up. Deleting #{COMPILED_ASSETS_DIR}"
    FileUtils.rm_rf COMPILED_ASSETS_DIR if Dir.exists? COMPILED_ASSETS_DIR
  end
  
  
  # *************
  # IOS
  # *************

  # Setting up ios requires that we:
  #   - We support the livingpic:// scheme - for this we need to change a few core classes AppDelegate.m and MainViewcotroller.m, and
  #     we need to add the custome scheme to LivingPic-Info.plist
  #   - we add custom plugins, which means we update the config.xml code and add the source code to xcode directory
  #   - we add the stuff that almost never changes, such as the platform icons and splash screens...

  task :setup_ios => [
                      :setup_for_ios, 
                      :support_custom_scheme_ios, 
                      :add_custom_plugins_ios, 
                      :setup_project_images_ios, 
                      :stage_config_ios, 
                      :complete_setup_ios]

  task :add_custom_plugins_ios => [:add_custom_plugins_src_ios]
  task :support_custom_scheme_ios => [:add_changed_src_ios, :update_info_plist]
  
  desc  "Set up the variables for an ios build"
  task :setup_for_ios do
    @platform = :ios
    @device = :iphone
    @app_dir = APP_DIR_IOS
    @target_assets_base_dir = File.join(@app_dir,"www")
    puts "app directory = #{@app_dir}"
  end

  # Automatically set the xcode version to what we have now
  task :set_ios_version do 
    file = File.join(APP_DIR_IOS_PROJECT,"#{APP_NAME}-Info.plist")
    info = File.open(file,"r") { |f| f.read }
    # Unfortunately I once made the mistake of making the vesrion number be 51 and now I have to make sure it's above that each time
    # so instead of 1.8 I have to write 1.80
    info.sub!(%r{(<key>CFBundleShortVersionString</key>\s+<string>).*?(</string>)}mi,'\1'+"#{'%.2f' % Version.current.number}"+'\2')
    info.sub!(%r{(<key>CFBundleVersion</key>\s+<string>).*?(</string>)}mi,'\1'+"#{Version.current.build}"+'\2')
    info = File.open(file,"w") { |f| f.write info }
  end
  
  desc "Add ios updated src files"
  task :add_changed_src_ios do
    puts "  Supporting livingpic:// scheme in the IOS environment by copying our customized main classes"
    src_dir= File.join(Rails.root,'vendor','cordova','ios')
    # Now copy the classes
    tdir = File.join(APP_DIR_IOS_PROJECT,"Classes")
    files = Dir.entries(File.join(src_dir,"Classes")).select { |fn| ! fn.starts_with?(".")}.map { |f| File.join(src_dir,"Classes",f)}
    FileUtils.cp(files,tdir)
  end

  # Now update the plist to add the livingpic:// schema....
  task :update_info_plist do
    puts "  Updating xcode to add livingpic:// schema"
    require "rexml/Document"
    filename = "#{APP_NAME}-Info.plist"
    plist_file = File.join(APP_DIR_IOS,APP_NAME,filename)
    p = File.read(plist_file)
    if p.index("CFBundleURLTypes")
      puts "   -> #{plist_file} already contains bundle schemes"
    else
      text =<<-END

      <key>CFBundleURLTypes</key>
      <array>
        <dict>
          <key>CFBundleTypeRole</key>
          <string>Editor</string>
          <key>CFBundleURLName</key>
          <string>livingpic</string>
          <key>CFBundleURLSchemes</key>
          <array>
            <string>livingpic</string>
          </array>
        </dict>
      </array>
      END
      if m=p.match( %r{<key>CFBundleSignature</key>.*?</string>}m )
        p=m.pre_match + m[0] + text + m.post_match
      end
      File.write("#{plist_file}",p)
    end
  end

  desc "Add custom ios plugins"
  task :add_custom_plugins_src_ios do
    puts "Adding the custom ios plugins"
    src_dir= File.join(Rails.root,'vendor','cordova','ios')
    src_plugins_dir = File.join(src_dir,"Plugins")
    target_plugins_dir = File.join(APP_DIR_IOS_PROJECT, "Plugins")

    %w{AlbumInterface}.each do |plugin|
      puts "   Installing Plugin #{plugin}"
      sdir = File.join(src_plugins_dir,plugin,"classes")
      ddir = File.join(target_plugins_dir,plugin)
      puts "   Removing old destination directory #{ddir}"
      FileUtils.rm_rf ddir
      Dir.mkdir ddir 
      files = Dir.entries(sdir).select { |fn| ! fn.starts_with?(".")}.map { |f| File.join(sdir,f) } 
      FileUtils.cp(files,ddir)
      Dir.chdir File.join(src_plugins_dir,plugin,"js")
      Dir.glob("*.js" ).each do |source|
        FileUtils.cp(source, asset_dir_ios("js"))
      end
    end
  end

  def add_config_feature(doc, name, platform,value=nil)
    if doc.elements["widget/feature[@name='#{name}']"]
      puts "    config.xml already includes the #{name} plugin"
      false
    else
      features = doc.get_elements("widget/feature")

      e = REXML::Element.new("feature")
      e.add_attribute("name",name)
      e.add_element("param", {"name" => "#{platform}-package", "value" => value || name})
      features.first.root.insert_after features.last, e   
      puts "    Added plugin #{name} to config.xml"
      true
    end
  end
  
  # no longer used as we copy config.xml from our source tree.
  # Update the config.xml file with our plugins
  task :update_config_ios  do
    puts "  Updating the ios config.xml file for custom plugins"
    require "rexml/Document"
    Dir.chdir File.join(APP_DIR, "platforms","ios",APP_NAME)
    config_doc = REXML::Document.new File.read("config.xml")

    if add_config_feature(config_doc,"AlbumInterface","ios")
      File.open("config.xml", "w") do |f|
        config_doc.write(f,2)
      end
    end
  end
  
  task :stage_config_ios do
    # Stage the Ios config.xml
    puts "Copying ios config.xml to target"
    source_file = File.join( Rails.root, "vendor", "cordova", "ios","config.xml")
    FileUtils.cp( source_file, APP_DIR_IOS_PROJECT )
  end
  
  desc "Copy the IOS icons for Farhad - someday this will be deprecated"
  task :setup_project_images_ios do
    puts "Copying ios icons"
    source_icon_dir = File.join( Rails.root,"app","assets", "images", "res", "icon", "ios" )
    target_icon_dir = File.join(APP_DIR_IOS_PROJECT,"Resources","icons")
    # iphone icons
    [29,40,50,57,60,72].each do |resolution|
      FileUtils.cp( "#{source_icon_dir}/icon-#{resolution}.png","#{target_icon_dir}/icon-#{resolution}.png")
      FileUtils.cp( "#{source_icon_dir}/icon-#{resolution}-2x.png","#{target_icon_dir}/icon-#{resolution}@2x.png")
    end

    puts "Copying ios splash screens"
    source_icon_dir = File.join( Rails.root,"app","assets", "images", "res", "screen", "ios" )
    target_icon_dir = File.join(APP_DIR_IOS_PROJECT,"Resources","splash")
    # iphone
    %w(Default.png Default@2x.png Default-568h@2x~iphone.png Default~iphone.png Default@2x~iphone.png).each do |file|
      FileUtils.cp( "#{source_icon_dir}/#{file}","#{target_icon_dir}/#{file}")
    end

   # ipad
   # FileUtils.cp( "#{source_icon_dir}/icon-72.png","#{target_icon_dir}/Icon-72.png")
   # FileUtils.cp( "#{source_icon_dir}/icon-72-2x.png","#{target_icon_dir}/Icon-72@2x.png")    
  end

  task :complete_setup_ios do
    puts <<-END
    ********************************
    *   NOTE NOTE NOTE NOTE
    ********************************

    You must complete the setup by manually:
    1)  Add the custom plugin src code to xcode.  Go to
        the Plugins folder, right-click and select "Add files to project ..." and add the src code 
        for each of custom plugins.

    2)  Pray and launch xcode
    END

  end

  # *********
  # ANDROID
  # *********

  task :setup_android => [:setup_for_android, 
                          :add_custom_plugins_android, 
                          :setup_project_images_android,
                          :stage_android_manifest,
                          :stage_android_config
                          ]

  task :add_custom_plugins_android => [
                                      :add_custom_plugins_src_android,
                                      # Comment out b/c now coping config from our src tree.
                                      # :update_config_android
                                      # Comment out b/c now loading webintent via plugin which should take care of it for us
                                      #:update_manifest_android
                                      ]

  desc  "Set up the variables for an android build"
  task :setup_for_android do
    @platform = :android
    @device = :android
    @app_dir = APP_DIR_ANDROID
    @target_assets_base_dir = File.join(@app_dir, "assets","www") 
    puts "app directory = #{@app_dir}"
  end
  
  task :stage_android_manifest do
    # Stage the Android manifest
    source_dir = File.join( Rails.root, "vendor", "cordova", "android","AndroidManifest.xml")
    puts "Copying AndroidManifest.xml to #{APP_DIR_ANDROID}"
    FileUtils.cp( source_dir, APP_DIR_ANDROID )
  end
  
  task :stage_android_config do
    # Stage the Android config.xml
    source_file = File.join( Rails.root, "vendor", "cordova", "android","config.xml")
    target_dir = File.join(APP_DIR_ANDROID, "res", "xml")
    puts "Copying android config.xml to #{target_dir}"
    FileUtils.cp( source_file, target_dir )
  end
  
  task :set_android_version do
    Dir.chdir(APP_DIR_ANDROID)
    am_text = File.open("AndroidManifest.xml", "r"){ |f| f.read }
    am_text.gsub!(/android:versionCode=("|')\d+("|')/, "android:versionCode='#{ANDROID_RELEASE_VERSION_CODE}'" )
    am_text.gsub!(/android:versionName=("|').+?("|')/, "android:versionName='#{ANDROID_RELEASE_VERSION_NAME}'" )
    File.open("AndroidManifest.xml", "w"){ |f| f.write am_text }
  end
  
  # Copy the source file to the target if it doesn't exist.  Leave it if it exists, 
  # unless if matches the package name, in which case we overwrite it, 
  # Expect src and target to be absolute paths
  def copy_to_target(src_path,target_base_path,package_name)
    require 'pathname'
    target_path = File.basename(target_base_path) == File.basename(src_path) ? target_base_path :  File.join(target_base_path, File.basename(src_path))
    # puts "#{package_name}: #{src_path} -> #{target_base_path}"
    # If source path is a directory....
    if File.directory? src_path 
      
      raise "File type inconsistency between #{src_path} and #{target_path}" if File.exist?(target_path) && !File.directory?(target_path)

      # If the directory already exists, remove it
      if File.exist?(target_path) && File.basename(src_path) == package_name
        puts "  #{package_name}: removing existing directory #{target_path}"
        FileUtils.rm_rf(target_path)
      end

      Dir.mkdir(target_path) unless File.directory? target_path
      Dir.glob("#{src_path}/[^.]*").each do |f|
        copy_to_target(f,target_path,package_name)
      end
    elsif File.file? src_path
      # Not a directory...
      raise "File type inconsistency between #{src_path} and #{target_path}" if File.exist?(target_path) && File.directory?(target_path)
      here = Pathname.new Rails.root
      relative_source = Pathname.new(src_path).relative_path_from(here)
      relative_target = Pathname.new(target_path).relative_path_from(here)
      puts "  Copying #{relative_source} to #{relative_target}"
      FileUtils.cp src_path,target_path
    end
  end

  desc "Add custom android plugins"
  task :add_custom_plugins_src_android do
    puts "Adding the custom android plugins"
    src_plugins_dir = File.join(Rails.root,'vendor','cordova','android',"Plugins")
    target_plugins_dir = File.join(APP_DIR_ANDROID, "src")
    Dir.mkdir target_plugins_dir unless File.directory? target_plugins_dir

    # Copy the noplanbees utils java package 
    puts "Adding noplanbees utils java package"
    source_dir = File.join( Rails.root, "vendor", "cordova", "android", "utils", "com", "noplanbees")
    target_dir = File.join(APP_DIR_ANDROID, "src", "com")
    FileUtils.cp_r( source_dir, target_dir )

    # Copy the Gson library
    puts "Adding noplanbees gson library package"
    source_dir = File.join( Rails.root, "vendor", "cordova", "android", "libs",".")
    target_dir = File.join(APP_DIR_ANDROID, "libs")
    FileUtils.cp_r( source_dir, target_dir )

    # MAybe TODO - search directory and pull out plugin list but right now I have other crap in there
    %w{albuminterface keyboard}.each do |plugin|
      puts "Installing Plugin #{plugin}"
      sdir = File.join(src_plugins_dir,plugin,"src")
      # The directory structure is something like com.noplanbees.albuminterface, but we could also have
      # other plugins from noplanbees, so let's iterate down the directory tree and at each step see if the 
      # directory exists in the target, and if not, create it, except if the directory name is the same as the
      # plugin name, in which case we delete it and overwrite it

      copy_to_target(sdir,target_plugins_dir,plugin)

      Dir.chdir File.join(src_plugins_dir,plugin,"js")
      Dir.glob("*.js" ).each do |source|
        FileUtils.cp(source, asset_dir_android("js"))
      end
    end

  end

  # Update the config.xml file with our plugins
  task :update_config_android  do
    puts "  Updating the android config.xml file for custom plugins"
    require "rexml/Document"
    Dir.chdir File.join(APP_DIR_ANDROID,"res","xml")
    config_doc = REXML::Document.new File.read("config.xml")

    added = add_config_feature(config_doc,"AlbumInterface","android","com.noplanbees.albuminterface.AlbumInterface") 
    added = add_config_feature(config_doc,"Keyboard","android","com.noplanbees.keyboard.Keyboard") || added
    if added
      File.open("config.xml", "w") do |f|
        config_doc.write(f,2)
      end
    end
  end

  task :setup_project_images_android do 
    # Launcher icons and splash screens
    puts "Staging android res icons"
    
    # Kill the drawable stub directories put there by phonegap
    android_res_dir = File.join(APP_DIR_ANDROID, "res")
    Dir.glob(File.join(android_res_dir, "drawable*")).each{|drw_dir| FileUtils.rm_rf drw_dir}
    Dir.glob( File.join(Rails.root,"app","assets","images", "res", "icon", "android", "drawable*") ).each do |source|
      FileUtils.cp_r( source, android_res_dir ) 
    end
  end
  
  desc "Set debuggable in android manifest"
  task :set_manifest_not_debuggable do
    set_manifest_debuggable(false)
  end
  
  task :set_manifest_debuggable do
    set_manifest_debuggable(true)
  end
  
  def set_manifest_debuggable(value)
    require "rexml/document"
    Dir.chdir(APP_DIR_ANDROID)
      
    android_manifest_doc = nil
    File.open("AndroidManifest.xml", "r") do |f|
      android_manifest_doc = REXML::Document.new f
    end
    
    el = android_manifest_doc.get_elements("//manifest/application").first
    raise "set_manifest_debuggable: expecting to find an application element in AndroidManifest.xml" if el.blank?
   
    el.attributes["android:debuggable"] = value 
    
    File.open("AndroidManifest.xml", "w") do |f|
      android_manifest_doc.write(f,2)
    end
    puts "Set android:debuggable = #{value} in AndroidManifest.xml"
  end
  
  desc "Build and deploy on andriod"
  task :deploy_android => [
                           :build_for_android, 
                           :run_android
                           ] do
    puts "Build and deploy on android complete."
  end
  
  desc "Build andriod release"
  task :deploy_android_release => [
                                   :build_for_android_release, 
                                   :sign_for_android_release
                                   ] do
    puts "Build android release complete."
  end
  
  task :build_for_android do
    Dir.chdir(APP_DIR_ANDROID)
    puts "Building locally for android."
    puts "running 'system ant debug'"
    puts system "ant debug" 
  end
  
  desc "Build for android release"
  task :build_for_android_release do
    Dir.chdir(APP_DIR_ANDROID)
    puts "Building for android release apk."
    puts system "ant release" 
  end
  
  # Note this only needs to be done once but I put it here to preserve how I did it.
  desc "generate android key"
  task :generate_android_key => :environment do
    Dir.chdir KEYSTORE_DIR_ANDROID
    system "keytool -genkey -v -keystore #{APP_CONFIG[:site_name]}.keystore -alias #{APP_CONFIG[:site_name]} -keyalg RSA -keysize 2048 -validity 10000"
  end
  
  desc "Sign for android release"
  task :sign_for_android_release => :environment do
    puts "Signing android release version"
    key = File.join(KEYSTORE_DIR_ANDROID, "#{APP_CONFIG[:site_name]}.keystore")
    bin = File.join(APP_DIR_ANDROID, "bin")
    app = File.join(bin, "#{APP_CONFIG[:site_name]}-release-unsigned.apk")
    result = File.join(bin, "#{APP_CONFIG[:site_name]}-release-signed_aligned.apk")
    system "jarsigner -verbose -sigalg MD5withRSA -digestalg SHA1 -keystore #{key} #{app} #{APP_CONFIG[:site_name]}"
    puts system "jarsigner -verify #{app}"
    puts system "zipalign -f -v '4' #{app} #{result}"
    puts system "zipalign -c -v '4' #{result}"
    puts "Signed aligned release apk should be in: #{result}"
  end
  
  task :run_android => :environment do
    Dir.chdir(APP_DIR_ANDROID)
    puts "Installing on USB attached device."
    puts system "adb -d install -r bin/#{APP_CONFIG[:site_name]}-debug.apk"
    puts system "adb shell am start -a android.intent.action.MAIN -n #{APP_SIGNATURE}/.#{APP_CONFIG[:site_name]}"
  end

  ##################
  #  ONE-TIME IMAGE BUILDS
  ##################

  # This is just a convience rake task to be used one time. It operates on our snapshot images source. It takes 
  # the file server/app/assets/images/res/icon/launch_icon.png and it resizes it using imagemagic and puts it in 
  # the appropriate folders for android and ios under /app/assets/images/res/icon
  task :make_icons_android do
    puts "Resizing launch_icon for android"
    icon_dir = File.join(Rails.root,"app", "assets", "images", "res", "icon")
    orig_icon = File.join(icon_dir, "icon_lp.png")
    
    android_paths_for_size = {
      512 => ["icon-512"],
      96 => ["drawable", "drawable-xhdpi"],
      72 => ["drawable-hdpi"],
      48 => ["drawable-mdpi"],
      36 => ["drawable-ldpi"],
    }
    
    android_icon_dir = File.join(icon_dir, "android")
    FileUtils.rm_rf( Dir.glob File.join(android_icon_dir, "*") )
    android_paths_for_size.keys.each do |sz|
      android_paths_for_size[sz].each do |pth|
        puts pth
        target = File.join(android_icon_dir, pth)
        Dir.mkdir target
        system "convert #{orig_icon} -resize #{sz}x#{sz}\\! #{target}/icon.png"
      end
    end
  end
  
  task :make_icons_ios do
    puts "Building icon set for iphone"
    icon_dir = File.join(Rails.root,"app", "assets", "images", "res", "icon")
    orig_icon = File.join(icon_dir, "icon_lp.png")
    iphone_file_names_for_size = {
      29  => "icon-29.png",
      58  => "icon-29-2x.png",
      40  => "icon-40.png",
      80  => "icon-40-2x.png",
      50  => "icon-50.png",
      100  => "icon-50-2x.png",
      57  => "icon-57.png",
      114 => "icon-57-2x.png",
      60 => "icon-60.png",
      120 => "icon-60-2x.png",
      72  => "icon-72.png",
      144 => "icon-72-2x.png",
      1024 => "icon-1024.png"
    }
    iphone_icon_dir = File.join(icon_dir, "ios")
    FileUtils.rm_rf( Dir.glob File.join(iphone_icon_dir, "*.png") )
    iphone_file_names_for_size.keys.each do |sz|
      fn = iphone_file_names_for_size[sz]
      puts fn
      target = File.join(iphone_icon_dir, fn)
      system "convert #{orig_icon} -resize #{sz}x#{sz} #{target}"
    end
  end
  
  task :make_icons => [:make_android_icons, :make_ios_icons]


  ##################
  #  Misc
  ##################

  task :help do
    puts <<-END
Tasks of interest include:
- backup_cordova_project: create a backup of the existing cordova project
- create_cordova_project: create a new cordova project using the existing cordova node package
- setup_(ios|android): setup the ios environment.  This does things are rarely change, such as copying the plugins, 
        updating the images, and setting up the URL schemes.  You can run the sub-tasks such as 
    setup_project_images_(ios|android): Move the project logo, splash pages to the app directory
    support_custom_scheme_(ios|android): update the .plist/Manifest file and add the source files to 
        support living:// scheme
    add_custom_plugins_(ios|android): Move the custom plugins in our source directory (3rd party plugins 
        that support the cordova plugin CLI are moved during project creation)
- build_(ios|android): you know what this is....
- make_icons_(ios|android): Using a single 1024x1024 image, create the appropriate icon sizes for the environment.  
        These are placed in appropriate source directories
    END
  end


  ##################
  # DEPRECATED
  ################## 
  
  # DEPRECATED
  CORDOVA_VERSION = "2.9.0"
  CORDOVA_FRAMEWORKS_DIR = "#{ENV['HOME']}/dev/cordova/cordova-#{CORDOVA_VERSION}"
  
  # FOR CLOUD BUILDS DEPRECATED
  PHONEGAP_BUILD_FILES = Dir.glob File.join(Rails.root,"config", "phonegap", "phonegap_build", "*")

  desc "Stage files in app directory and push to github so that phonegap cloud build can pull and build"
  task :build_remote => [:clean_app_dir, :precompile, :render_html, :stage_common_files, :git_push, :clean_up] do 
    puts "Ready for phonegap_build. To complete build use build.phonegap.com and click update code."
  end

  task :stage_certs do   
    puts "Copying phonegap config files and certs"
    PHONEGAP_BUILD_FILES.each{|f| FileUtils.cp(f, File.join(APP_DIR, "www"))}
  end
  
  desc "Push www directory to github so that it can be pulled from there when using phonegap build."
  task :git_push do    
    # Push to git repo if it exists.
    if Dir.exists?(File.join(APP_DIR, ".git"))
      puts "Git repo exists pushing changes up to git repo for phonegap build."
      Dir.chdir(APP_DIR)
      puts system "git add www"
      puts system "git commit -m 'commit by rake app:package' www"
      puts system "git push origin master"
    else
      puts "No Git repo exists not pushing changes to repo."
    end
  end
  # END FOR CLOUD BUILDS
  
  # Deprecated
  # NOTE: This is now directly put into the AndroidManifest in vendor/cordova-plugins/android
  desc "Add intent filter to AndroidManifest.xml"
  task :update_manifest_android do
    require "rexml/document"
    Dir.chdir(APP_DIR_ANDROID)
    android_manifest_doc = nil
    File.open("AndroidManifest.xml", "r") do |f|
      android_manifest_doc = REXML::Document.new f
    end

    if android_manifest_doc.elements["manifest/application/activity/intent-filter/data[@android:scheme]"]
      puts "  support for livingpic scheme already exists in manifest file"
    else
      activity = android_manifest_doc.elements["manifest/application/activity"]
      
      intent_filter_str = <<-EOF
      <manifest xmlns:android="http://schemas.android.com/apk/res/android">
        <intent-filter>
          <data android:scheme="livingpic" />
          <action android:name="android.intent.action.VIEW" />
          <category android:name="android.intent.category.BROWSABLE" />
          <category android:name="android.intent.category.DEFAULT" />
        </intent-filter>
      </manifest>
  EOF
      
      intent_filter_doc = REXML::Document.new intent_filter_str
      intent_filter = intent_filter_doc.root.elements["intent-filter"]
      activity.add_element intent_filter
      
      File.open("AndroidManifest.xml", "w") do |f|
        android_manifest_doc.write(f,2)
      end
      puts "  intent filter for livingpic scheme added to AndroidManifest.xml"
    end
  end
  
  # DEPRECATED
  desc "Set up the environment for android"
  task :setup_android_environment do
    puts "  Copying config.xml"
    src_dir= File.join(Rails.root,'vendor','cordova','android')
    target_dir = File.join(APP_DIR_ANDROID,'res','xml')
    FileUtils.cp(File.join(src_dir,'config.xml'),target_dir)
  end

  # Note I create a dummy platforms/android directory when building for iphone for simplicity in writing this rake file. 
  # For simplicity stage_common_files does the work for staging the files for android and iphone at the same time and staging for 
  # android requries at least platforms/android/assets/www to exist. In the android build flow this is accomplished by 
  # create_android_platform.
 # DEPRECATED
 task :ensure_platform_android_assets do 
    puts "Creating dummy platform/android/assets/www directory so that stage_local_files works."
    Dir.chdir(APP_DIR)
    tree = File.join(APP_DIR)
    %w(platforms android assets www).each do |node|
      tree = File.join(tree, node)
      Dir.mkdir tree unless Dir.exists? tree
    end
  end
  
  # DEPRECATED
  task :anrdoid_remove_stubs do
    # Remove the stub files phonegap installs
    [ 
      File.join(asset_dir_android("js"), "index.js"),  
      File.join(asset_dir_android("css"), "index.css"),
      asset_dir_android("img")
    ].each do |stub|
      # FileUtils.rm_rf stub if Dir.exists? stub      
      FileUtils.rm stub if File.exists? stub
    end
  end

  # DEPRECATED
  # Creates the android platform in the target android directory
  task :create_android_platform => :environment do 
    Dir.chdir(CORDOVA_FRAMEWORKS_DIR)
    puts "Creating platforms/android using cordova-framework VERSION: #{CORDOVA_VERSION}"
    puts "./lib/android/bin/create #{APP_DIR_ANDROID} #{APP_SIGNATURE} #{APP_CONFIG[:site_name]}"
    puts system "./lib/android/bin/create #{APP_DIR_ANDROID} #{APP_SIGNATURE} #{APP_CONFIG[:site_name]}"
  end
  
  # DEPRECATED
  task :stage_cordova_js_ios do    
     # Farhads Xcode build
     puts "Staging cordova.js and PushNotification.js for xcode from server directory"
     # Cordova and cordova_plugins.js have to be at the top www directory
     source = File.join(Rails.root,"vendor","cordova","ios","js","cordova.js")
     FileUtils.cp(source, asset_dir(""))
     source = File.join(Rails.root,"vendor","cordova","ios","js","cordova_plugins.js")
     FileUtils.cp(source, asset_dir(""))

     # We can put the other js files in the subdirectories
     target_dir = asset_dir("js")
     source = File.join(Rails.root,"vendor","cordova","ios","Plugins","PushWoosh","js","PushNotification.js")
     FileUtils.cp(source, target_dir)
     source = File.join(Rails.root,"vendor","cordova","ios","Plugins","AlbumInterface","js","AlbumInterface.js")
     FileUtils.cp(source, target_dir)
  end
  
  # DEPRECATED
  task :delete_cordova_crap do
    # now remove some of the crap that cordova leaves around
    # FileUtils.rm_rf(File.join(APP_DIR,"www"))
    [asset_dir_ios,asset_dir_android].each do |dir|
      Dir.chdir dir
      File.delete "config.xml" if File.exist? "config.xml"
      Dir.glob("cordova-app-hello-world*").each do |dir|
        FileUtils.rm_rf(dir)
      end
    end
  end
  
  # DEPRECATED
  task :stage_cordova_js_android do
     target_dir = asset_dir("js")
     puts "Staging cordova.js for Android. Using version: #{CORDOVA_VERSION} for android platform from cordova-framework that was put there by cordova/create"
     # Remove move the consistent version put here by cordova/create into js under our generic name of cordova.js.
     source = ( Dir.glob File.join(asset_dir(""), "cordova*.js") ).first
     target = File.join( target_dir, "cordova.js" )
     if source
       FileUtils.mv( source, target )    
     else
       puts "WARNING: could not find source file #{source} - perhaps moved already?"
     end    
   end
   

   # DEPRECATED
  desc "Add cordova plugins"
  # task :android_add_cordova_plugins => [:android_add_cordova_plugins_code, :android_add_cordova_plugins_to_config_xml]
  task :android_add_cordova_plugins => [:android_add_cordova_plugins_code]
  
  # DEPRECATED
  task :android_add_cordova_plugins_code do
    puts "Staging cordova webintent plugin for android."
    Dir.chdir(APP_DIR_ANDROID)
    puts "Staging webintent js"
    source_js = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "webintent", "js", "webintent.js")
    FileUtils.cp( source_js, android_asset_dir("js") )
    
    puts "Staging webintent java"
    source_dir = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "webintent", "src", "com", "borismus")
    target_dir = File.join(APP_DIR_ANDROID, "src", "com")
    FileUtils.cp_r( source_dir, target_dir )
    
    # Copy the album interface code, both the .java and .js files
    puts "Staging album_interface src"
    source_dir = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "albuminterface", "src", "com", "noplanbees")
    target_dir = File.join(APP_DIR_ANDROID, "src", "com")
    FileUtils.cp_r( source_dir, target_dir )

    source_js = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "albuminterface", "js","AlbumInterface.js")
    FileUtils.cp( source_js,  android_asset_dir("js") )
    
    # Copy the Keyboard plugin code, both the .java and .js files Note this depends on noplanbees being created above
    puts "Staging keyboard plugin src"
    source_dir = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "keyboard", "src", "com", "noplanbees", "keyboard")
    target_dir = File.join(APP_DIR_ANDROID, "src", "com", "noplanbees")
    FileUtils.cp_r( source_dir, target_dir )

    source_js = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "keyboard", "js","Keyboard.js")
    FileUtils.cp( source_js,  android_asset_dir("js") )
    
    
    if ANDROID_PUSH_WOOSH
      puts "Staging cordova pushwoosh plugin for android."
      Dir.chdir(APP_DIR)
      puts "Staging pushwoosh js"
      source_js = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "pushwoosh", "js", "PushNotification.js")
      FileUtils.cp( source_js, android_asset_dir("js") )
      
      puts "Staging pushwoosh java"
      source_dir = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "pushwoosh", "src", "com", "pushwoosh")
      target_dir = File.join(APP_DIR_ANDROID, "src", "com")
      FileUtils.cp_r( source_dir, target_dir )

      if ANDROID_PUSHWOOSH_USE_SOURCE
        puts "Staging pushwoosh arellomobile and google src"
        source_dir = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "pushwoosh", "src", "com", "arellomobile")
        target_dir = File.join(APP_DIR_ANDROID, "src", "com")
        FileUtils.cp_r( source_dir, target_dir )
        source_dir = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "pushwoosh", "src", "com", "google")
        FileUtils.cp_r( source_dir, target_dir )
      else
        source_dir = File.join( Rails.root, "vendor", "cordova", "android", "Plugins", "pushwoosh", "lib","Pushwoosh.jar")
        target_dir = File.join(APP_DIR_ANDROID, "libs")
        FileUtils.cp( source_dir, target_dir )
      end

    end
  end
  
  
  # FF: Don't really need to use this - config.xml doesn't change very often - it's more straightforward to 
  # just have the file and copy it over like w/ ios
  # DEPRECATED
  task :android_add_cordova_plugins_to_config_xml do
    require "rexml/document"
    Dir.chdir( File.join(APP_DIR_ANDROID, "res", "xml") )
    config_doc = nil
    File.open("config.xml", "r") do |f|
      config_doc = REXML::Document.new f
    end
    plugins = config_doc.elements["cordova/plugins"]

    # Add the webintent plugin
    plugin_str = "<plugin name='WebIntent' value='com.borismus.webintent.WebIntent' />"
    plugin_doc = REXML::Document.new plugin_str
    plugin = plugin_doc.root
    plugins.add_element plugin
    
    File.open("config.xml", "w") do |f|
      config_doc.write(f,2)
    end

    if ANDROID_PUSH_WOOSH
      # Now add the push notifcation config
      plugin_str = "<plugin name='PushNotification' value='com.pushwoosh.plugin.pushnotifications.PushNotifications' onload='true'/>"
      plugin_doc = REXML::Document.new plugin_str
      plugin = plugin_doc.root
      plugins.add_element plugin

      File.open("config.xml", "w") do |f|
        config_doc.write(f,2)
      end
    end

    puts "Add plugin to config.xml complete."
  end

  # DEPRECATED
  desc "Render the index.html file for iphone"
  task :render_html_ios do
    ENV['PRECOMPILE_TARGET'] = 'device'
    Dir.mkdir File.join(APP_DIR_IOS,"www") unless Dir.exist? File.join(APP_DIR_IOS,"www")
    target_index = File.join(APP_DIR_IOS,"www","index.html")
    url = "http://localhost:3000/app/build_page?device_type=iphone&device_release_version=#{ENV['DEVICE_RELEASE_VERSION']}"
    puts "Creating the app html index file in #{target_index} from #{url}"
    File.open(target_index,"w") do |f|
      f.write open(url).read
    end 
  end
  
  # DEPRECATED
  desc "Render the index.html file for android."
  task :render_html_android do  
    ENV['PRECOMPILE_TARGET'] = 'device'
    target_index = File.join(asset_dir_android(""), "index.html")
    url = "http://localhost:3000/app/build_page?device_type=android&device_release_version=#{ENV['DEVICE_RELEASE_VERSION']}"
    puts "Creating the app html index file in #{target_index} from #{url}"
    File.open(target_index,"w") do |f|
      f.write open(url).read
    end 
  end
  

  task :test do
    puts "test"
  end


end  
