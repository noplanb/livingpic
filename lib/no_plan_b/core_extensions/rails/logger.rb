class Logger
    
  def self.define_mine(level)
    module_eval <<-end_eval
      def my_#{level}(*args)
        indicator = (args.size == 2 ) ? args.shift : '#'*8
        self.#{level}(indicator + ' ' + args[0].to_s)
      end
    end_eval
  end
  [:debug, :info, :error, :fatal, :warn].each {|level| define_mine(level) }
  
  def my_trace(*args)
    my_info(*args) if ENV["TRACE_LOG"]
  end
  
  def tmp_debug(*args)
    my_debug('>'*20,*args)
  end
  
  def tmp_info(*args)
    my_info('>'*20,*args)
  end
  
  def mark(*args)
    my_info(">>>> MARK=> ",*args)
  end
  
  def format_message(severity, timestamp, progname, msg) 
    "#{severity.upcase}: #{timestamp.strftime("%b %d %H:%M:%S")}: #{msg.to_s.gsub(/\n/, '').lstrip}\n"
  end
end
