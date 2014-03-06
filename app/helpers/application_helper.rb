module ApplicationHelper

  include SessionManager, Commons  
  
  def is_public_release?
    # logger.tmp_debug "DEVICE_RELEASE_VERSION = #{ENV['DEVICE_RELEASE_VERSION']}"
    device_target? && ENV["DEVICE_RELEASE_VERSION"] && (ENV["DEVICE_RELEASE_VERSION"].match(/store/) || ENV["DEVICE_RELEASE_VERSION"].match(/release/))
  end
  
  def is_development_release?
    !is_public_release?
  end
  
  def release_version
    Version.new(ENV["DEVICE_RELEASE_VERSION"]).display
  end

  def requires_weinre
    ENV['PRECOMPILE_TARGET'] == 'device' &&
    @device_type == :android &&
    ENV["DEVICE_RELEASE_VERSION"] && !ENV["DEVICE_RELEASE_VERSION"].match(/release/)
  end
  
  def browser_target?
    ENV['PRECOMPILE_TARGET'] == 'browser'
  end
  
  def device_target?
    ENV['PRECOMPILE_TARGET'] == 'device'
  end
  
  def app_redirect_base_url(using_app)
    using_app ? APP_CONFIG[:app_schema] : "/app"
  end  
  
end
