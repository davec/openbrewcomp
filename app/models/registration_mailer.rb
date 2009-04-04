# -*- coding: utf-8 -*-

require 'action_mailer/version'
require 'tmail/version'

class RegistrationMailer < ActionMailer::Base

  def password(email_to, login_id, password, options = {})
    sent_at = options.delete(:time) || Time.now
    @competition_name = options[:competition_name] || 'Competition'
    init_common_headers(email_to, :time => sent_at)
    @subject = 'Login information'
    @body    = { :login_id => login_id,
                 :password => password,
                 :competition_name => @competition_name }
  end

  def judge_invite(email_to, message_text, access_key, options = {})
    sent_at = options.delete(:time) || Time.now
    @competition_name = options[:competition_name] || 'Competition'
    init_common_headers(email_to, :time => sent_at)
    @subject = options.delete(:subject) || @competition_name
    @body = { :message => message_text,
              :access_key => access_key,
              :competition_name => @competition_name }
  end

  private

    def init_common_headers(recipients, options = {})
      @from       = "#{@competition_name} Registrar <#{APP_CONFIG[:account_mgmt_email]}>"
      @recipients = recipients
      @cc         = options[:cc]
      @bcc        = options[:bcc]
      @sent_on    = options[:time] || Time.now
      @headers    = { 'User-Agent' => "TMail #{TMail::VERSION::STRING} (ActionMailer #{ActionMailer::VERSION::STRING})" }
    end

end
