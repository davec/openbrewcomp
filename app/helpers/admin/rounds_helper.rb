# -*- coding: utf-8 -*-

module Admin::RoundsHelper

  def flights_column(record)
    if record.flights.nil?
      '-'
    elsif controller.action_name == 'show'
      h(record.flights.collect(&:to_label).join("\n")).gsub("\n",'<br />')
    else
      num_to_show = 3
      flights = record.flights.sort_by{|f| [f.award_id,f.name]}.first(num_to_show+1).collect(&:to_label)
      flights[num_to_show] = '…' if flights.length == num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
      h(flights.join(', '))
    end
  end

end
