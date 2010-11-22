# -*- coding: utf-8 -*-

module Admin::CompetitionDataHelper

  VIEW_DATE_FORMAT = '%A, %B %e, %Y'
  EDIT_DATE_FORMAT = '%B %e, %Y'
  VIEW_TIME_FORMAT = '%A, %B %e, %Y at %l:%M %p'
  EDIT_TIME_FORMAT = '%B %e, %Y %I:%M %p'

  def mcab_column(record)
    record.mcab? ? 'Yes' : 'No'
  end

  def entry_registration_start_time_column(record)
    record.entry_registration_start_time.nil? ? '-' : record.entry_registration_start_time.strftime(controller.action_name == 'edit' ? EDIT_TIME_FORMAT : VIEW_TIME_FORMAT)
  end

  def entry_registration_end_time_column(record)
    record.entry_registration_end_time.nil? ? '-' : record.entry_registration_end_time.strftime(controller.action_name == 'edit' ? EDIT_TIME_FORMAT : VIEW_TIME_FORMAT)
  end

  def judge_registration_start_time_column(record)
    record.judge_registration_start_time.nil? ? '-' : record.judge_registration_start_time.strftime(controller.action_name == 'edit' ? EDIT_TIME_FORMAT : VIEW_TIME_FORMAT)
  end

  def judge_registration_end_time_column(record)
    record.judge_registration_end_time.nil? ? '-' : record.judge_registration_end_time.strftime(controller.action_name == 'edit' ? EDIT_TIME_FORMAT : VIEW_TIME_FORMAT)
  end

  def competition_start_time_column(record)
    record.competition_start_time.nil? ? '-' : record.competition_start_time.strftime(controller.action_name == 'edit' ? EDIT_TIME_FORMAT : VIEW_TIME_FORMAT)
  end

  def competition_date_column(record)
    record.competition_date.nil? ? '-' : record.competition_date.strftime(controller.action_name == 'edit' ? EDIT_DATE_FORMAT : VIEW_DATE_FORMAT)
  end

  def local_timezone_form_column(record, input_name)
    # NOTE: Leave out the GMT-based timezones. Their names are confusing (TZInfo
    # uses the Olsen timezone database which uses POSIX rules for the offset
    # values, and these are the reverse of what most people expect when working
    # with timezones) and not terribly useful since they do not support any
    # DST offsets (daylight saving time is regional and cannot be applied to a
    # generic GMT-based offset). It's better to only offer geographically-based
    # timezones instead (plus UTC).
    zones = TZInfo::Timezone.all.
              reject { |z| z.to_s =~ /GMT/ }.
              map { |z| [ z.to_s, z.name ] }
    select :record, :local_timezone, zones,
           { :prompt => '- Please select a time zone -'},
           { :name => input_name }
  end

end
