# Include hook code here
require 'no_plan_b'

# # Make sanilog available to ActionControllers and ActiveRecords for now, both in their class methods and in their 
# # instance methods
ActionController::Base.send(:include,Sanilog)
ActionController::Base.send(:extend,Sanilog)
ActiveRecord::Base.send(:include,Sanilog)
ActionController::Base.send(:extend,Sanilog)

# Add the event logging to the controller and active records
ActionController::Base.send(:include,NoPlanB::Rails::ErrorLogging)
ActiveRecord::Base.send(:include,NoPlanB::Rails::ErrorLogging)
ActionController::Base.send(:include,NoPlanB::Rails::EventLogging)
ActiveRecord::Base.send(:include,NoPlanB::Rails::EventLogging)
ActionController::Base.send(:include,NoPlanB::Rails::ConvenienceMethods)
ActionView::Base.send(:include,NoPlanB::Rails::ConvenienceMethods)

# Add the helpers to basic views
ActionView::Base.send(:include,NoPlanB::Helpers::DisplayFormatHelper)
ActionView::Base.send(:include,NoPlanB::Helpers::DeviceAssetPathHelper)

# GARF: Farhad Todo: not important but if easy I cant figure out how to get DeviceAssetPathHelper methods in scope for the sprockets 
# environment that exists when it processes assets. Using complete pathnames for now. The following line does not work. 
Sprockets::Helpers::RailsHelper.send(:include,NoPlanB::Helpers::DeviceAssetPathHelper)

# ActiveSupport.on_load(:action_view) do
#   include ::NoPlanB::Helpers::DeviceAssetPathHelper
#   app.assets.context_class.instance_eval do
#     include ::NoPlanB::Helpers::DeviceAssetPathHelper
#   end
# end

# Add the default scopes to the ActiveRecord
# ActiveRecord::Base.send(:include,NoPlanB::NamedScopes)

Rails.logger.class.send(:include, NoPlanB::ExtendedLogging)

