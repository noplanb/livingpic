module BatchProcess
  extend self

  # Batch process the indicated items in chunks
  def in_chunks(klass,options={})
    silent = options.delete(:silent)
    count = klass.count(:conditions => options[:conditions])
    counted = options[:offset] || 0
    options[:limit] ||= 100
    while ( counted < count ) do 
      puts counted unless silent
      klass.find(:all,options.merge({:offset => counted})).each { |record|
        yield record
      }
      counted += options[:limit]
    end    
  end

  alias_method :run, :in_chunks
  
end
