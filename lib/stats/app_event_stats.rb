class AppEventStats
  unloadable

  attr_reader :search_patterns

  APP_EVENTS_LOG = File.join(Rails.root,'log','app_events.log')

  # example search options = {:occasion_id => 10, :user_id => 3, :page => "gallery"}
  def initialize(options={})
    @search_patterns = []
    process_search_options(options)
  end

  def process_search_options(options)
    @search_patterns << %{"id"=>"#{options[:occasion_id]}"} if options[:occasion_id]
    @search_patterns << %{: [#{options[:user_id]}]} if options[:user_id]
    @search_patterns << %{page=##{options[:page]}} if options[:page] 
    raise "You must specify at least one search option." if @search_patterns.blank?
  end

  def grep_string
    grep_str = %{fgrep '#{@search_patterns[0]}' #{APP_EVENTS_LOG}}
    @search_patterns[1..-1].each do |patt|
      grep_str += %{ | fgrep '#{patt}'}
    end
    return grep_str
  end

  def count
    command = grep_string + " | wc -l"
    %x[#{command}][/\d+/].to_i
  end

  def list
    system grep_string
  end

end