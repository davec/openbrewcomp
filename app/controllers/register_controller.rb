# -*- coding: utf-8 -*-

class RegisterController < ApplicationController

  before_filter :get_registration_status
  before_filter :login_required, :only => [ :online, :judge_confirmation ],
                                 :if => :is_registration_open?

  # If the start of registration is less than 2 weeks away,
  # tell us how much time remains before registration opens.
  COUNTDOWN_PERIOD = 2.weeks

  def online
    registration_start_time_utc = [ competition_data.entry_registration_start_time_utc,
                                    competition_data.judge_registration_start_time_utc ].compact.min
    if competition_data.is_registration_future? &&
      Time.now.utc.between?(registration_start_time_utc - COUNTDOWN_PERIOD,
                            registration_start_time_utc)
      @time_to_go = TimeInterval.difference_in_words(Time.now.utc, registration_start_time_utc)
    elsif competition_data.is_registration_open?
      @auto_open_judge = flash[:auto_open_judge]
      @auto_edit_judge_id = flash[:auto_edit_judge_id]
      flash.keep#(:warning)
    end
  end

  def judge_confirmation
    if competition_data.is_registration_open?
      judge = Judge.find_by_access_key(params[:key])
      flash[:auto_open_judge] = true
      unless judge.nil?
        judge.update_attribute(:user_id, current_user.id)
        flash[:auto_edit_judge_id] = judge.id
      else
        flash[:warning] = 'Confirmation key was not found'
      end
    end
    redirect_to online_registration_path
  end

  def forms
    @competition_name = CompetitionData.instance.name
  end

  private

    def is_registration_open?
      @is_registration_open
    end

    def get_registration_status
      @registration_status        = competition_data.registration_status
      @is_registration_open       = competition_data.is_registration_open?
      @entry_registration_status  = competition_data.entry_registration_status
      @is_entry_registration_open = competition_data.is_entry_registration_open?
      @judge_registration_status  = competition_data.judge_registration_status
      @is_judge_registration_open = competition_data.is_judge_registration_open?
    end

    END_OF_TIME = Time.at(0x7fffffff).freeze  # The end of time as we know it
    def registration_time_remaining
      # If no end time is set, use a date "far" in the future -- we pick the
      # end of Unix time (2038-01-18T15:14:07Z) since anything beyond this
      # point causes Ruby to throw a TypeError in Date#-.
      ([ competition_data.entry_registration_end_time,
         competition_data.judge_registration_end_time].compact.max || END_OF_TIME) - Time.now.utc
    end

end
