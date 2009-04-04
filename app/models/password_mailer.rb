# -*- coding: utf-8 -*-

require 'action_mailer/version'
require 'tmail/version'

class PasswordMailer < ActionMailer::Base

  # Send a reset code the the user
  def forgot_password(password)
    setup_email(password.user)
    @subject << 'You have requested to change your password'
    @body[:reset_code] = password.reset_code
    # NOTE: Adjust TTL to whole hours so we don't get something like
    # "2 days, 23 hours, and 59 minutes" for the time interval.
    @body[:ttl] = TimeInterval.interval_in_words(((password.expires_at - Time.now.utc)/3600).ceil * 3600)
  end

  ## Send a reset confirmation email (not currently used)
  #def reset_password(user)
  #  setup_email(user)
  #  @subject << 'Your password has been reset.'
  #end

  protected
  
    def setup_email(user)
      competition_name = CompetitionData.instance.name
      @recipients  = user.email
      @from        = "#{competition_name} Account Management <#{APP_CONFIG[:account_mgmt_email]}>"
      @subject     = "[#{competition_name}] "
      @sent_on     = Time.now
      @headers     = { 'User-Agent' => "TMail #{TMail::VERSION::STRING} (ActionMailer #{ActionMailer::VERSION::STRING})" }
      @body[:user] = user
    end

end
