# -*- coding: utf-8 -*-

class Admin::JudgingSessionsController < AdministrationController

  active_scaffold :judging_session do |config|
    config.actions << :sortable
    config.label = 'Judging Sessions'

    config.list.columns = [ :description, :date, :start_time, :end_time, :flights ]

    config.create.label = 'Create Judging Session'
    config.create.link.label = 'New Judging Session'
    config.create.columns = [ :description, :date, :start_time, :end_time ]

    config.update.columns = [ :description, :date, :start_time, :end_time ]

    config.show.label = 'Show Judging Session'
    config.show.columns = [ :description, :date, :start_time, :end_time, :flights ]

    # Disable column sorting
    config.columns[:description].sort = false
    config.columns[:date].sort = false

    # Required fields
    [ :description, :date ].each do |f|
      config.columns[f].required = true
    end

    # UI overrides
    config.columns[:description].options = { :size => 50, :maxlength => 255 }
    [ :date, :start_time, :end_time ].each do |f|
      use_time = !!f.to_s.match(/_time$/)
      config.columns[f].form_ui = :calendar_date_select
      config.columns[f].options = {
        :year_range => Time.now.year-1..Time.now.year+1,
        :time => use_time,
        :minute_interval => 15,
        :popup => 'force',
        :month_year => 'label',
        :class => "date#{use_time ? 'time' : ''}-input"
      }
    end
  end

  protected

    def after_create_save(record)
      # We need to reload the record after creation to get the start and end
      # times converted back to local time from the stored UTC time since AS
      # doesn't do a reload on the record -- thus the model's after_find
      # method is not invoked to do the UTC->local conversion -- beore it's
      # sent off to be displayed in the list view.
      record.reload
    end

end
