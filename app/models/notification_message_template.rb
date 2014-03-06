# Manages the Notificaiton Message templates
# Think of the template as having a context and an id.  The context refers to "invite", or "photo_tag", or "like"
# that is, gives a clue to the type of message that we are sending
# The version refers to the number for this message
class NotificationMessageTemplate
  
  require 'yaml'
  require 'erb'
  
  attr_accessor :type, :body, :template, :version
  attr_reader :prepared
  
    # =================
  # = Class Methods =
  # =================
  class << self
  
    def config_file=(value)
      @config_file = value
    end  

    def config_file
      @config_file
    end
    
    def load_config_file(file=nil)
      self.config_file = file if file
      @templates ||= YAML.load_file(config_file).symbolize_keys
    end
  
    def templates(type=nil)
      load_config_file
      type ? @templates[type] : @templates
    end

    def count(type=nil)
      load_config_file
      type ? @templates[type].length : @templates.inject(0) { |sum,(k,v)| sum+= v.length }
    end
    
    def latest_version(type)
      load_config_file
      @templates[type].keys.sort.last
    end
    
    # Get the text message associated with a type
    def [](type,version=nil)
      type = type.to_sym
      load_config_file
      version ||= latest_version(type)
      template = @templates[type][version.to_i] or raise Exception, "Unable to find version #{version} of template #{type}"
      new(type,template,version)
    end

    def reset
      @templates = nil
      load_config_file
    end
  end

  # ====================
  # = Instance Methods =
  # ====================
  
  def initialize(type,template,version)
    self.type = type
    self.template = template
    self.version = version
  end
  
  # fills in the template with the associate objects
  # Each parameter must be passed
  # e.g. if the template references user and date, you should pass
  # template.fill(:user => joe, :date => Time.now)
  # This method returns a string that contains the filled in template
  def fill_old(params={})
    params.each do |key,value|
      instance_variable_set("@#{key}".to_sym,value)
    end
    self.body =   (template).result binding
    self.body
  end
  
  # per http://geek.swombat.com/rails-rendering-templates-outside-of-a-contro
  # since I want to include the ApplicationHelper
  def fill(params={})
    view = ActionView::Base.new(ActionController::Base.view_paths, {})  
     
    class << view  
     include ApplicationHelper, NotificationHelper
    end  
    # render will automatically HTML escape anything in between <%=  .... %> even if the template is not html
    # this cryptic code is a way to get around a problem in which unescapeHTML returns an error TypeError: can't dup NilClass
    # which seems to be associated with unviewable characters in the ';', perhaps as a result of encoding or something.
    # Note that encoding using <%== %> also disables the html escaping, but we may forget to do that so I'm leaving this in
    # as a safeguard - FF 2013-04-16
    self.body = CGI.unescapeHTML(view.render(:inline => template, :locals => params).gsub(';',';'))
    # self.body = view.render(:inline => template, :locals => params)
  end

  def identifier
    "#{type}.#{version}"
  end
    
end
