class Version

  unloadable

  attr_reader :target, :build, :number
  @current = nil

  class << self
    def current_build
      `svn info #{Rails.root}` =~ /Revision: (\d+)/ && $1
    end

    def current_number
      APP_CONFIG[:app_version]
    end

    def current_string
      "#{current_number}b#{current_build}"
    end

    def current
      @current ||= new(current_string)
    end
    
    def out_of_date_severity(version_string)
      version_number = Version.new(version_string).number
      return :mandatory if version_number and version_number < APP_CONFIG[:madatory_version_upgrade_threshold]
      return :optional if version_number and version_number < APP_CONFIG[:app_version]
      return nil
    end
  end

  # Initialize
  def initialize(version_string=Version.current_string)
    @full = version_string
    if m = version_string.match(/(?:(store|release).*)?(\d+\.\d+)(b\d+)?\w?$/)
      @target = case m[1]
      when 'store' then :production
      when 'release' then :public
      else :development
      end

      @number = m[2].to_f
      @build = m[3][1..-1]
    else
      raise "Bad version string format #{version_string}"
    end
  end

  # Return if the user is on a current version and build
  def current?
    @build == Version.current.build
  end

  # Return if this matches the most current public release, which is presumably the 
  # last public version.  
  # TODO - Assumes that the current number is the app_version in the config file, which 
  # is probbably not correct
  def current_public?
    @number == Version.current.number
  end

  # 
  def display
    "#{@number}b#{@build}#{target_string}" 
  end

  def v
    "#{@number}b#{@build}"
  end

  private

  def target_string
    case @target
    when :public then "r"
    when :production then "p"
    when :development then "d"
    end
  end

end