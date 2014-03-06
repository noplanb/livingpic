class Object
  def self.expose_as_instance_method(*class_methods)
    class_methods.each { |class_method| 
      define_method(class_method) { |*args|
        self.class.send(class_method,*args)
      }
    }
  end
  
  def or_if_nil(alternative)
    nil? ? alternative : self
  end
  
  def or_if_blank(alternative)
    if respond_to?(:blank?) 
      blank? ? alternative : self
    elsif nil? 
      alternative
    else
      if respond_to?(:empty?) && respond_to?(:strip)
        self.strip.empty? ? alternative : self
      elsif respond_to?(:empty?)
        self.empty? ? alternative : self
      else
        self
      end
    end
  end
end

if __FILE__ == $0
  class Foo
    def self.bar
      puts "bar"
    end
    expose_as_instance_method :bar
    
    def self.baz
      puts 'baz'
    end
    
    def self.zab
      puts "zab"
    end
    
    expose_as_instance_method :baz,:zab
  end
  
  Foo.bar
  Foo.new.bar
  Foo.new.baz
  Foo.zab
  Foo.new.zab
end
