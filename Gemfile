source 'https://rubygems.org'

gem 'rails', '3.2.12'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'sqlite3'

# gem 'mysql'
gem 'mysql2'
gem 'debugger', "~> 1.6.5"
gem 'hashie'

# gem "paperclip", "~> 3.0"
# gem "paperclip", :git => "https://github.com/sanielfishawy/paperclip.git"
# gem "paperclip", :git => "git://github.com/etcetc/paperclip.git"
# FF 2013-06-17: this version has a fix for some problem I encountered but for the life of me I can't remember what it was
gem "paperclip" # , :git => "git://github.com/thoughtbot/paperclip.git"
# gem "paperclip-meta"  # , :git => "git://github.com/y8/paperclip-meta.git"
# FF 2013-11-11: this version has a correction to auto_orient prior to getting the geometry
gem "paperclip-meta" , :git => "git://github.com/etcetc/paperclip-meta.git"


gem 'twilio-rb'

gem 'aws-sdk'
# gem 'rake', '~> 10.1.0'

gem 'resque'
gem 'quick_magick'
gem 'geocoder'

gem 'npb_logging', :git => "git://github.com/etcetc/npb_logging.git"
# gem "npb_logging"
gem 'console_candy', :git => 'git://github.com/etcetc/console_candy.git'
gem 'npb_notification', :git => 'git://github.com/etcetc/npb_notification.git'
# gem 'npb_notification'

gem 'httparty'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :development do
  gem 'populator'
  gem 'faker'
  gem 'pry-rails'
end

group :test do 
  # version 0.6 seems to have a bug
  gem "single_test", '= 0.5.2'
end

group :production do
  # For handling exception notifications
  # gem 'exception_notification', :require => "exception_notifier"
  gem 'exception_notification', :git => "git://github.com/etcetc/exception_notification.git", :require => "exception_notifier"
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
