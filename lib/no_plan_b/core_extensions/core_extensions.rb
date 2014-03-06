# Our core extensions to ruby and rails
module NoPlanB
  module CoreExtensions
    # puts "loading core extensions"
    %w( shared ruby rails ).each do |dir|
      Dir.glob(File.join(File.dirname(__FILE__),dir,'[^.]*.rb')).each do |f|
        require f 
      end
    end
  end
end
