# Stores and retrieves simple objects that can be converted to and from json in a file
# I created this to cache statistics for occasions and particpants that take some time to compute
# in order to speed up the admin/stats pages.

class SimpleCache
  
  attr_reader :dir
  
  def initialize(dir=File.join(Rails.root, "tmp", "stats-cache"))
    @dir = dir
  end
  
  def store(obj, name)
    @name = name
    File.open(path, "w"){|f| f.write obj.to_json}
  end
  
  def fetch(name)
    @name = name
    JSON.parse(IO.read(path))
  end
  
  def path
    File.join(dir, @name)
  end
end
