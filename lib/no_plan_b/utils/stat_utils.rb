module NoPlanB
module StatUtils
  
  # bin the objects based upon the results of applying the proc to the histogram
  # called object or object after it's been proc'ed should should support <=> and -
  # bin(Team.gender_female, )
  def bin(object_array,options={},&proc)    
    bins = []
    puts "proc=#{proc.inspect}"
    sorted_array,min,max = [],0,0
    if proc 
      sorted_array = object_array.sort { |x,y| proc.call(x) <=> proc.call(y) } 
      max = options[:min] || proc.call(sorted_array.last)
      min = options[:max] || proc.call(sorted_array.first)
    else
      sorted_array = object_array.sort 
      min = object_array.first
      max = object_array.last
    end
    step_size = options[:step_size] || 1.0*(max - min + 1e-8)/(options[:steps] || 10)
    puts "sorted_array = #{sorted_array.inspect}, min=#{min}, max=#{max}, step_size=#{step_size}"
    raise "Error - step size calculated to be <= 0" if step_size <= 0
    binned_objects = []
    sorted_array.each { |o| 
      i= (( (proc ? proc.call(o) : o ) - min )/step_size).floor
      puts "i=#{i}"
      (binned_objects[i] ||= [] )<< o
    }
    binned_objects
  end
  
  # Requires a block to extract the appropriate time value
  # time_bin is:
  #  :day_of_month => bins the evens based upon day of month (1..31)
  #  :day_of_week  => bins the evens based upon day of week Sunday...Saturday
  #  :time_of_day  => bins the evens based upon time of day (0..23)
  # Returns a hash with the count for each bin
  def time_histogram(time_bin,object_array)
    binned = Hash.new(0)
    p = Proc.new { |date|
      case time_bin
      when :day_of_month then date.strftime("%d")
      when :day_of_week then date.strftime("%A")
      when :time_of_day then date.strftime("%H")
      else 
        nil
      end
    }
    
    object_array.each { |v| 
      date = yield v
      if date and bin = p.call(date) 
        binned[bin] += 1
      end
    }    
    binned
  end
  
  # Requires a block to extract the appropriate date value
  # Returns an array of hashes, containing the following hash elements
  #  :month => text for month, in Jan, Feb,... format
  #  :year => year in 0n format
  #  :id => a unique bin ID (actually the year/month representation in 2008.08 format)
  #  :objects => :array of input objects that map into that month
  def bin_by_month(object_array)
    binned_month = []
    object_array.each { |v| 
      date = yield v
      next unless date
      month = date.strftime("%b")
      year =  date.strftime("%y")
      id = date.strftime("%Y.%m").to_f
      if e = binned_month.find { |z| z[:month] == month }
        e[:objects] << v
      else
        binned_month << { :month => month, :id => id, :year => year, :objects => [v] }
      end
    }    
    # Now sort by month and return
    binned_month.sort{ |a,b| a[:id] <=> b[:id] }    
  end

  # Return bin - if there is no bin, create one
  # coupled with structure returned by "bin_by_month"
  def bin_for_id(binned_array,id)
    binned_array.find { |v| v[:id] == id} or {:year => id.floor, :month => Date.parse("#{id.to_s.split.last}/1/2008").strftime("%b"),:objects => []}
  end
  
  # If not objects found, then just return an empty array
  def objects_for_bin_id(binned_array,id)
    (r = binned_array.find { |v| v[:id] == id}  )? r[:objects] : []
  end
  
  # Convert a 2D structure to CSV
  def to_csv(array2d,filename=nil)
    fp = File.open(filename,'w') if filename
    array2d.each { |x| 
      (fp || STDOUT).puts Array(x)*','
    }
    fp.close if fp
  end
  
end
end