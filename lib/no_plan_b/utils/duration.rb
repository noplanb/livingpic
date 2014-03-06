class Duration
  
  def initialize(s)
    if String === s
      x = s.split(':')
      secs = x.pop || 0
      mins = x.pop || 0
      hrs = x.pop || 0
      @secs = hrs.to_i*3600 + mins.to_i*60 + secs.to_i
    else
      @secs = s.to_i || 0
    end
  end

  def to_s
    hrs = @secs/3600 
    mins = (@secs - hrs*3600)/60
    secs = @secs - hrs*3600 - mins*60
    h = hrs > 0 ? ('%02d' % hrs) : nil
    m = mins > 0 ? ('%02d' % mins) : '00' 
    s = "%02d" % secs
    [h,m,s].compact.join(':')
  end
  
  def seconds
    @secs
  end
  
end

if __FILE__ == $0
  ["03:19:22","06:13", "19", "0"].each do |d|
    dd = Duration.new(d)
    puts "#{d} == #{dd}"
  end
end