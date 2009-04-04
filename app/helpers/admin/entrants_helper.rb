# -*- coding: utf-8 -*-

module Admin::EntrantsHelper

  def is_team_column(record)
    record.is_team? ? "Yes" : "No"
  end

  def postal_address_column(record)
    h(record.postal_address).strip.squeeze("\n").gsub("\n", "<br />")
  end

  def entries_column(record)
    if record.entries.blank?
      '<b>Add Entries</b>'
    else
      #entries = record.entries.sort{|x,y| x.id <=> y.id}.collect{|v| v.to_label}

      ## Show the first few entries
      #num_to_show = 3
      #entries = record.entries.sort{|x,y| x.id <=> y.id}.first(num_to_show+1).collect(&:to_label)
      #entries[num_to_show] = '…' if entries.length == num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
      #h(entries.join(', '))

      "<b>Edit Entries</b> (#{record.entries.length})"
    end
  end

end
