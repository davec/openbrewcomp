# -*- coding: utf-8 -*-

require 'action_mailer/version'
require 'tmail/version'

class JudgeMailer < ActionMailer::Base

  def judge_invite(judge, message, options = {})
    competition_name = CompetitionData.instance.name

    @recipients = %Q{"#{judge.first_name} #{judge.last_name}" <#{judge.email}>}
    @from       = "#{competition_name} Registrar <#{APP_CONFIG[:account_mgmt_email]}>"
    @subject    = options[:subject] || competition_name
    @sent_on    = Time.now
    @headers    = { 'User-Agent' => "TMail #{TMail::VERSION::STRING} (ActionMailer #{ActionMailer::VERSION::STRING})" }
    @body       = { :message => message,
                    :access_key => judge.access_key,
                    :competition_name => competition_name }
  end

end
