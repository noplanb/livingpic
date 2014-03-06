module Enumerable

  # Creates a histogram of the enumerable - hmm, not sure why I put this here and not in Array
  def histogram
    inject(Hash.new(0)) { |h, x| h[x] += 1; h}
  end
  
  def to_histogram
    raise "Use histogram instead - to_histrogam has been deprecated"
  end
  
  # Return an array of the ids of the objects w/in
  def ids
    map { |x| x.id }
  end

end
