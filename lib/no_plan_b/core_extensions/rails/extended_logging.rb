# Extend whatever the logger object to include a number of additional methods

module NoPlanB::ExtendedLogging

  def self.included(base)
    base.send(:include,InstanceMethods)
    # If we're using the buffered logger, then we need to 
    # alias it so we can change the message format
    if base.instance_methods.include?("add") && !base.instance_methods.include?("add_with_classic_message")
      base.class_eval <<-END
        # puts "ExtendedLogging: Changing log message format"
        alias_method :add_with_classic_message, :add
        SeverityMap = [:debug,:info,:warn,:error,:fatal,:unknown].map{ |s| s.to_s.upcase }
        def add(severity, message = nil, progname = nil, &block)
          message = do_format_message(SeverityMap[severity],Time.now,progname,message) unless message.nil?
          add_with_classic_message(severity, message, progname, &block)
        end
      END
    end
  end
  
  module InstanceMethods
    def self.define_mine(level)
      module_eval <<-end_eval
      def my_#{level}(*args)
        indicator = (args.size == 2 ) ? args.shift : '#'*8
        self.#{level}(indicator + ' ' + args[0].to_s)
      end
      end_eval
    end
    [:debug, :info, :warn, :error, :fatal].each {|level| define_mine(level) }
  
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

    def do_format_message(severity, timestamp, progname, msg) 
      "#{severity}: #{timestamp.strftime("%b %d %H:%M:%S")}: #{msg.to_s.gsub(/\n/, '').lstrip}\n"
    end
  end
end
