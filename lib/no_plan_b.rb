module NoPlanB   
  
  # puts "Loading NoPlanB module"
  # TODO - at some point it would be better to use the autoload mechanism rather than explicitly requiring these models
  %w(core_extensions utils helpers).each do |dir|
    Dir.glob(File.join(File.dirname(__FILE__),'no_plan_b',dir,'[^.]*.rb')).each do |f|
      require f
    end
  end
end
