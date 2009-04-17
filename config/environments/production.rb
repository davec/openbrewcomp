# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
# HACK: Avoid eager loading of application classes during migrations.
# TODO: Remove this hack for Rails 2.3 (where it is no longer needed)
config.cache_classes = !(File.basename($0) == "rake" && !ARGV.grep(/db:/).empty?)

# Enable threaded mode
# config.threadsafe!

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# HACK: If deploying in a sub-directory, set relative_url_root because it's not
# picked up from the web server since Rails 2.2.
# See http://code.google.com/p/phusion-passenger/issues/detail?id=169 and
# http://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/1946
# for more info.
# config.action_controller.relative_url_root = '/openbrewcomp'

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false
