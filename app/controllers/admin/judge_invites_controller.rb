# -*- coding: utf-8 -*-

class Admin::JudgeInvitesController < AdministrationController
  before_filter :set_action_mailer_options, :only => :send_email

  def index
    judge_registration_open = competition_data.is_judge_registration_open?
    have_judge_email_addresses = Judge.email_count > 0
    @allowed = judge_registration_open && have_judge_email_addresses
    @status = if @allowed
                'OK'
              elsif !judge_registration_open
                case competition_data.judge_registration_status
                when CompetitionData::REGISTRATION_STATUS_FUTURE
                  "Judge registration is not yet open. Judge invites cannot be sent before #{competition_data.judge_registration_start_time.strftime('%A, %B %e, %Y at %l:%M %p')}."
                when CompetitionData::REGISTRATION_STATUS_PAST
                  "Judge registration closed #{competition_data.judge_registration_end_time.strftime('%A, %B %e, %Y at %l:%M %p')}."
                else
                  'No judge registration dates have been defined.'
                end
              else
                'No judge email addresses could be found.'
              end
    @message_template = JudgeInvite.message_template rescue nil
    @default_subject = JudgeInvite.default_subject rescue nil
  end

  def send_email
    unless params[:invite][:message].blank?
      begin
        # Sending email takes too long for more than a trivial number of
        # judges, so we use the spawn plugin to fork off the processing.
        spawn do
          Judge.email_invites(:subject => params[:invite][:subject],
                              :message => params[:invite][:message],
                              :target  => params[:invite][:target])
        end
        flash[:notice] = "Spawned process to send email to #{Judge.email_count(:target => params[:invite][:target])} judges."
      rescue Exception => e
        flash[:judge_invite_error] = e.to_s
      end
    else
      flash[:judge_invite_error] = 'You must provide a message'
    end
    redirect_to admin_judge_invitations_path
  end

end
