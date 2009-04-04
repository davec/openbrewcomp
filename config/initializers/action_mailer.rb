# Be sure to restart your web server when you modify this file.

# Configure ActionMailer

## For SMTP delivery

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => 'fqdn.of.smtp.host', # The hostname of the SMTP server
  :port => 25,                     # Change only if the SMTP server is on a non-standard port
  :domain => 'fqdn.of.sender',     # The hostname of the sender
  :username => nil,                # Username for authentication, if required
  :password => nil,                # Password for authentication, if required
  :authentication => nil           # Authentication method (:plain, :login, or :cram_md5), if required
}

## For sendmail delivery

# Note: The sendmail delivery method only works if the From address in the
# email matches the actual sender, or the sender is a trusted sender and the
# -f option is used to set the sender name specified in the From address
# (i.e., both addresses must match).

#ActionMailer::Base.delivery_method = :sendmail
#ActionMailer::Base.sendmail_settings = {
#  :location => '/usr/sbin/sendmail', # The location of the sendmail program
#  :arguments => '-i -t'              # sendmail options
#}

