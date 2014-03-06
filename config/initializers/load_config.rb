APP_CONFIG = YAML.load_file("#{Rails.root}/config/app_config.yml")[Rails.env].symbolize_keys

# Now merge in any local config file changes
local_config_file = "#{Rails.root}/config/app_config_local.yml"
if File.exist? local_config_file
  APP_CONFIG.merge!(YAML.load_file(local_config_file)[Rails.env].symbolize_keys)
end