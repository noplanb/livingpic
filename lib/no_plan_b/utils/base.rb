module NoPlanB
  require  File.dirname(__FILE__) + '/logging'
  require  File.dirname(__FILE__) + '/sanilog'
  class Base

    include NoPlanB::Logging
    include ::Sanilog
  end
end