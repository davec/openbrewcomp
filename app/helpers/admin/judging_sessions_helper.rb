# -*- coding: utf-8 -*-

module Admin::JudgingSessionsHelper

  VIEW_DATE_FORMAT = '%A, %B %e, %Y'
  EDIT_DATE_FORMAT = '%B %e, %Y'
  VIEW_TIME_FORMAT = '%l:%M %p'
  EDIT_TIME_FORMAT = '%B %e, %Y %I:%M %p'

  def date_column(record)
    record.date.nil? ? (record.new_record? ? '' : '-') : record.date.strftime(['edit', 'new'].include?(controller.action_name) ? EDIT_DATE_FORMAT : VIEW_DATE_FORMAT)
  end

  def start_time_column(record)
    record.start_time.nil? ? '-' : record.start_time.strftime(controller.action_name == 'edit' ? EDIT_TIME_FORMAT : VIEW_TIME_FORMAT)
  end

  def end_time_column(record)
    record.end_time.nil? ? '-' : record.end_time.strftime(controller.action_name == 'edit' ? EDIT_TIME_FORMAT : VIEW_TIME_FORMAT)
  end

  def flights_column(record)
    record.flights.nil? ? '-' : "#{record.completed_flight_count} / #{record.flight_count}"
  end

  def flights_show_column(record)
    record.flights.nil? ? '-' : show_flights_table(record)
  end

  private

    def show_flights_table(record)
      table_width = '40em'
      returning String.new do |str|
        str << %Q{<table class="session-flights" style="width:#{table_width}"><tr><th>Flight</th><th>Round</th><th>Status</th></tr>}
        record.flights.sort_by{|f| [f.award_id,f.name]}.each do |flight|
          str << %Q{<tr class="#{cycle('odd-record', 'even-record')}"><td class="flight">#{h flight.name}</td><td>#{flight.round.position}</td><td>#{h flight.status_label}</td></tr>}
        end
        str << '</table>'
      end
    end

end
