APP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/settings.yml")[RAILS_ENV].symbolize_keys

# The setup config is only used for initial database setup
SETUP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/db_init.yml")[RAILS_ENV].symbolize_keys if File.basename($0) == 'rake'
