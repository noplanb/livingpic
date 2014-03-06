# Include all the modifications to active_record
module ActiveRecord
  Dir.glob(File.join(File.dirname(__FILE__),'active_record','*.rb')).each do |f|
    require f
  end
end
