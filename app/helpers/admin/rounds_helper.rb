# -*- coding: utf-8 -*-

module Admin::RoundsHelper

  def flights_column(record)
    return '-' if record.flights.nil?

    num_to_show = 3
    flights = sorted_flights(record).first(num_to_show+1).map(&:to_label)
    flights[num_to_show] = '…' if flights.length == num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
    h(flights.join(', '))
  end

  def flights_show_column(record)
    return '-' if record.flights.nil?
    h(sorted_flights(record).map(&:to_label).join("\n")).gsub("\n",'<br />')
  end

  private

    def sorted_flights(record)
      record.flights.sort_by{ |f| [ f.award_id, f.name ] }
    end

end
