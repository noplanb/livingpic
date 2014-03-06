class Module 

  # Loads the module files in the directory of the same name as this module
  # (we try lowercase and capitalized)
  # Call this with __FILE__!  that way, it knows where you are

  def load_module_files(current_file)
    dirname ||= name.split('::').last.downcase
    # puts "Loading files in directory #{dirname}, #{File.join(File.dirname(current_file),dirname)}"
    Dir.glob(File.join(File.dirname(current_file),dirname,'[^.]*.rb')).each do |f|
      require_dependency f
    end
  end
  
end
