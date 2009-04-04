# -*- coding: utf-8 -*-

class Admin::CompetitionDataController < AdministrationController

  cache_sweeper :competition_data_sweeper, :only => [ :update ]

  active_scaffold :competition_data do |config|
    config.actions = [ :list, :update, :show ]
    config.label = 'Competition Data'

    config.list.columns = [ :name, :competition_number, :competition_date,
                            :entry_registration_start_time, :entry_registration_end_time,
                            :judge_registration_start_time, :judge_registration_end_time ]

    config.update.columns = [ :name, :mcab, :competition_number,
                              :competition_date, :competition_start_time,
                              :entry_registration_start_time, :entry_registration_end_time,
                              :judge_registration_start_time, :judge_registration_end_time,
                              :local_timezone ]

    config.show.label = 'Show Competition Data'
    config.show.columns = [ :name, :mcab, :competition_number,
                            :competition_date, :competition_start_time,
                            :entry_registration_start_time, :entry_registration_end_time,
                            :judge_registration_start_time, :judge_registration_end_time,
                            :local_timezone ]

    # Virtual fields
    config.columns << :competition_start_time
    config.columns << :entry_registration_start_time
    config.columns << :entry_registration_end_time
    config.columns << :judge_registration_start_time
    config.columns << :judge_registration_end_time

    # Label overrides
    config.columns[:name].label = 'Competition Name'
    config.columns[:mcab].label = 'MCAB Qualifying Competition'
    config.columns[:competition_number].label = 'Competition ID'
    config.columns[:competition_date].label = 'Competition Date'
    config.columns[:competition_start_time].label = 'Competition<br />Start Time'
    config.columns[:entry_registration_start_time].label = 'Online Entry<br />Registration<br />Start Time'
    config.columns[:entry_registration_end_time].label = 'Online Entry<br />Registration<br />End Time'
    config.columns[:judge_registration_start_time].label = 'Online Judge<br />Registration<br />Start Time'
    config.columns[:judge_registration_end_time].label = 'Online Judge<br />Registration<br />End Time'
    config.columns[:local_timezone].label = 'Time Zone'

    # Descriptions
    config.columns[:competition_number].description = 'The competition number assigned by the BJCP'
    config.columns[:name].description = 'The competition name as registered with the BJCP'
    config.columns[:competition_date].description = 'The official date of the competition (for the BJCP competition report)'
    config.columns[:competition_start_time].description = 'The start time of the competition (for the countdown timer)'
    config.columns[:entry_registration_start_time].description = 'The time when online registration opens for entries'
    config.columns[:entry_registration_end_time].description = 'The time when online registration closes for entries'
    config.columns[:judge_registration_start_time].description = 'The time when online registration opens for judges'
    config.columns[:judge_registration_end_time].description = 'The time when online registration closes for judges'
    config.columns[:local_timezone].description = 'The timezone in which all competition times occur'

    # Required fields
    [ :name, :competition_number, :mcab, :local_timezone,
      :competition_date, :competition_start_time,
      :entry_registration_start_time, :entry_registration_end_time,
      :judge_registration_start_time, :judge_registration_end_time].each do |f|
      config.columns[f].required = true
      config.columns[f].sort = false
    end
    config.columns[:mcab].required = true
    config.columns[:competition_date].required = true
    config.columns[:competition_start_time].required = true
    config.columns[:entry_registration_start_time].required = true
    config.columns[:entry_registration_end_time].required = true
    config.columns[:judge_registration_start_time].required = true
    config.columns[:judge_registration_end_time].required = true
    config.columns[:local_timezone].required = true

    # UI overrides
    config.columns[:name].options = { :size => 50, :maxlength => 255 }
    config.columns[:mcab].form_ui = :checkbox
    config.columns[:competition_number].options = { :size => 10, :maxlength => 10 }
    config.columns[:competition_date].form_ui = :calendar_date_select
    # NOTE: A class name of datetime-input is set even on the
    # competition_date attribute just so the field lines up with the
    # other calendar fields on the form.
    [ :competition_date, :competition_start_time,
      :entry_registration_start_time, :entry_registration_end_time,
      :judge_registration_start_time, :judge_registration_end_time ].each do |f|
      config.columns[f].form_ui = :calendar_date_select
      config.columns[f].options = {
        :year_range => Time.now.year-1..Time.now.year+1,
        :time => !!f.to_s.match(/_time$/),
        :minute_interval => 15,
        :popup => 'force',
        :month_year => 'label',
        :class => 'datetime-input'
      }
    end
  end

end
