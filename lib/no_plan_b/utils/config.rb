# Warning - I have a mechanism here for easily setting and reading configuration parameters, simply by 
# saying: Config.key = value, for example, Config.protocol = http.  However, this has 2 side effects:
#   1) if you reference a variable that doesn't exist, it returns nil
#   2) if your variable has the same name as one of our methods, it executes the method and does not return your 
#      variable but rather executes our method!
module NoPlanB
  class Config
    require 'yaml'
    
    class << self
      
      attr_reader :config_file, :config, :config_load_time, :config_check_time
      attr_accessor :normalize_keys, :changed_check_delay
      
      # Parameters:
      # normalize_keys: whether to treat :key, 'key', 'KEY', and 'Key' as the same key (default true)
      # config_file: the configuration file 
      # changed_check_delay: how often to check if the config file has changed - if set too short, we're constantly checking for the
      #     File's modification time, which is too slow (default nil - meaning never)
      def configure(params={})
        # By default we normalize the keys - just makes life easier...
        @normalize_keys = true
        @changed_check_delay = nil
        params.each do |param,value|
          send("#{param}=".to_sym,value)
        end
      end
      
      # If the config file is set, we make sure that it exists.
      def config_file=(value)
        @config_file = value
        ensure_config_file_exists
        @config = nil
      end
      alias_method :file, :config_file
      alias_method :file=, :config_file=

      # What environment are we in
      # This can be overloaded by the sub-class
      # NOTE that the results are returned as a string and not as a symbol
      def environment
        (config_file && config["environment"]) || 
        case system
        when :ff then 'sandbox_ff'
        when :sani then 'sandbox_sani'
        when :staging then 'staging'
        else 'production'
        end 
      end

      def test_environment?
        environment.to_s != 'production' 
      end

      def dev_environment?
        [:ff,:sani].include?(environment)
      end
      
      def staging_environment?
        environment.to_s == 'staging'
      end
      
      # This is a bit dangerous to use ... Only for expert use
      # For simple setters, best to use the formalism
      #   Config.attribute = value
      # which sets the value for the appropriate environment (sadly, even if the value is not environment-dependent, it's
      # still set for the appropriate environment!)
      # For more complex ones, use 
      #   Config.set_value_for!(att1,att2,...,attn, value)
      #   which will set the valaue for att1=>att2....=>att2 where att1 through attn-1 are 
      #   hashes, and which will not trash the other keys for att1..attn-1
      def update(attribute_hash)
        config
        @config.merge!(attribute_hash)
        write_config_file
      end
      
      # Set the value for a configuration parameter
      # attributes is a list of attributes, with the last one being the value that the attribute is set to
      def set_value_for(*attributes)
        value = attributes.pop
        last_key = attributes.pop
        last_hash = config
        attributes.each { |att| 
          att = normalize(att)
          last_hash[att] = {} unless last_hash[att].is_a?(Hash)
          last_hash = last_hash[att]
        }
        last_hash[normalize(last_key)] = value          
        @config
      end
      
      def set_value_for!(*attributes)
        set_value_for(*attributes)
        write_config_file
      end
      
      def value_for(*attributes)
        x = config
        attributes.each { |att| 
          x = x[normalize(att)]
        }
        x
      end

      # This does the same thing as setting the value for the environment,
      # except at each step of the way it checks to see if there is an 
      # environment dependence
      def set_value_for_env!(*args)
        att = args.shift
        if value_env_dependent?(att)
          puts "#{att} is env_dependent"
          set_value_for!(att,environment,args.first)
        else
          set_value_for!(att,args.first)
        end
      end

      # Returns the environment dependent value for the indicated key
      # unless the key itself is 'environment', in which case we could
      # get into an infinite recursion if we didn't break it out
      def [](*attributes)
        x=config
        if normalized(attributes.first) == 'environment'
          x = config[normalize(:environment)]
        else 
          attributes.each { |att| 
            break if x.nil?
            x = env_dependent_value(x[normalize(att)])
          }
        end
        x
      end
      
      # Set the environment-dependent value for a given key and set of values
      # NOTE: if at any point we see that one of the attributes has a subkey for 
      # our current environment, we choose it
      def []=(*attributes)
        x=config
        # puts "config = #{x.inspect}"
        # puts "attributes = #{attributes.inspect}"
        attributes[0...-1].each_with_index { |att,i| 
          x = x[normalize(att)]
          # puts "att = #{att.inspect}, x=#{x.inspect}"
          if x.nil? 
            break
          elsif value_env_dependent?(x)
            attributes.insert(i+1,environment)
            break
          end
        }
        # puts "After checking attributes = #{attributes.inspect}"
        set_value_for!(*attributes)
      end
      
      
      # This could be called from the init or otherwise to make sure that the config file exists
      def ensure_config_file_exists
        write_config_file unless File.exists?(config_file)
      end

      def config
          @config ? load_config_file_if_changed : load_config_file
          @config
      end

      # We have the formalism that we allow someone to reference a config value 
      # simply by referencing it as a method, for example
      # Config.hit_lifetime.  This does have some unpleasant consequences: see top of file
      # I've disabled this and instead adopted the formalism of using Config[key] to avoid
      # any confusion.
      def method_missing_foo(method,*args)
        if method.to_s.match(/(\w+)=$/)
          att = $1
          if value_env_dependent?(att)
            set_value_for!(att,environment,args.first)
          else
            set_value_for!(att,args.first)
          end
        else
          env_value(method)
        end
      end
      
      # This is a hack to help us determine what system we're running on
      # Very Very hacky!!! but convenient
      def system
        h = `hostname`.strip
        if h.match(/^(onebeat|ff|farhad)/i)
          :ff
        elsif h.match(/^se-pro/)
          :sani
        elsif h.match(/^(bustameal|noplanbees)/)
          defined?(RAILS_ROOT) && RAILS_ROOT.index('/staging/') ? :staging : :production
        else
          :unknown
        end
      end
      
      # A simple method to determine if the environment is production
      def dev_mode?
        environment.to_s.downcase != 'production'
      end
      
      def reload
        load_config_file
      end
      
      private

      def load_config_file
        if ( File.exists?(config_file))
          # puts "Loading configuration file #{config_file}"
          @config_load_time = Time.now
          @config_check_time = Time.now
          @config = YAML.load_file(config_file) || {}
        else
          raise "NoPlanB::Config - Unable to find configuration file: #{config_file}"
        end
      end      
      
      def load_config_file_if_changed
        if @config_check_time && @changed_check_delay && (Time.now - @config_check_time) > @changed_check_delay
          @config_check_time = Time.now
          # puts "Checking if configuration file #{config_file} changed"
          load_config_file if File.mtime(config_file) > @config_load_time
        end
        @config    
      end
      
      def clear_config_file
        @config = nil
        File.trunc(config_file)
      end
      
      def write_config_file
        # puts @@config.inspect
        File.open(config_file,'w') do |f|
          f.write @config.to_yaml
        end
      end
      
      # We normalize the keys written to the config file, so that both symbols
      # and strings work and it's not capitalization-dependent
      def normalize(key)
        normalize_keys ? normalized(key) : key
      end
      
      def normalized(key)
        key.to_s.downcase
      end
      
      # When requesting the value for a configuration, this automatically returns the 
      # value for the indicated environment
      def env_value_deprecated(key)
        key = normalize(key)
        if value_env_dependent?(key)
          puts "key is env dependent"
          config[key][normalize(environment)] || config[key][normalize(:default)]
        else
          config[key]
        end
      end

      # Returns true if the value in environment-dependent
      def value_env_dependent?(value)
        res = environment && value.is_a?(Hash) && (value.has_key?(normalize(environment)) || value.has_key?(normalize(:default)))
        # puts "Checking if #{value.inspect} is environment-dependent: #{res}"
        res
      end
      
      # Returns the environment-dependent value
      def env_dependent_value(value)
        value_env_dependent?(value) ? (value[normalize(environment)] || default_value(value)) : value
      end
      
      # public :value_env_dependent?
      
      def default_value(value)
        default = normalize(:default)
        value[default] && (value[default].to_s.match(/^@(.+)/) ? value[normalize($1)] : value[default])
      end
      
    end
  end
end

if  __FILE__ == $0
  
  class Foo < NoPlanB::Config
    
    class <<self
      def environment
        "test"
      end
    end
    
    configure(:config_file => 'foo_config')
  end
  
  def subclass_tests
    Foo['a'] = "value_for_a"
    Foo['b','1'] = [1,2,3]
    Foo['c','test'] = 'value_for_test'
    Foo['c','production'] = 'value_for_production'
    Foo['c'] = 'value_for_test_again'
    puts Foo['c','production']  
  end
  
  def core_tests
    NoPlanB::Config.config_file="config_test.yml"
    NoPlanB::Config.update(:test => "writing", 'test2' => [1,2,3], 'test3' => { :att1 => '22', 'att2' => 'something else'})
    raise "Failed" unless NoPlanB::Config.value_for(:test) == 'writing'
    NoPlanB::Config.set_value_for!(:test, "reading")  
    raise "Failed" unless NoPlanB::Config.value_for(:test) == 'reading'
    NoPlanB::Config.set_value_for!('test3',:att1, 222)  
    raise "Failed" unless NoPlanB::Config.value_for('test3') === {:att1 => 222, 'att2' => 'something else'}
    NoPlanB::Config.normalize_keys = true
    NoPlanB::Config.set_value_for!('test3',:att2, "testing")  
    raise "Failed" unless NoPlanB::Config.value_for('test3','att2') === 'testing'
    raise "Failed" unless NoPlanB::Config['test3','att2'] == 'testing'
    raise "Failed" unless NoPlanB::Config[:test3,'att2'] == 'testing'
    raise "Failed" unless NoPlanB::Config[:test3,:att2] == 'testing'
    NoPlanB::Config[:test3,:att3] = 'another'
    raise "Failed" unless NoPlanB::Config[:test3,"att3"] == 'another'
    puts "Our pathetic core tests passed!"  
  end  
  
  class T < NoPlanB::Config
    configure(:config_file => "env_config.yml")
    puts "Env = #{environment.inspect}"
    puts "Running tests to check config file writing"
    raise "Failed #{T[:a]} should have been 'farhad'" unless T[:a] == 'farhad'
    T[:a] = 'ff'
    T.reload
    raise "Failed to write value 'ff' for :a => #{T[:a].inspect}" unless T[:a] == 'ff'
    raise "Failed #{T[:n]} should have been 180" unless T[:n] == 180
    T[:n] = 100
    T.reload
    raise "Failed #{T[:n]} should have been 100 after writing" unless T[:n] == 100

    # Now reset it
    T[:n] = 180
    T[:a] = 'farhad'
    puts "OK"
  end

  # core_tests
end
