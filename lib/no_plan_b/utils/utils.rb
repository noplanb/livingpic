module NoPlanB::Utils
  
  # Include all the rails utilities
  Dir.glob(File.join(File.dirname(__FILE__),"rails",'[^.]*.rb')).each do |f|
    require f
  end
  
  # We include these within this namespace for legacy reasons.
  require File.dirname(__FILE__) + '/stat_utils'
  require File.dirname(__FILE__) + '/text_utils'
  require File.dirname(__FILE__) + '/array_math_utils'
  require File.dirname(__FILE__) + '/number_utils'
  
  include NoPlanB::TextUtils
  include NoPlanB::StatUtils
  include NoPlanB::ArrayMathUtils
  include NoPlanB::NumberUtils
  extend self
end