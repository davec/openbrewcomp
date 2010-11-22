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
      #entries = record.entries.sort{|x,y| x.id <=> y.id}.map{|v| v.to_label}

      ## Show the first few entries
      #num_to_show = 3
      #entries = record.entries.sort{|x,y| x.id <=> y.id}.first(num_to_show+1).map(&:to_label)
      #entries[num_to_show] = '…' if entries.length == num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
      #h(entries.join(', '))

      "<b>Edit Entries</b> (#{record.entries.length})"
    end
  end

  def club_form_column(record, input_name)
    options = form_element_input_options(input_name, Entrant)
    options[:name] += '[id]'
    options[:onchange] = %Q{toggleOtherClubData('#{params[:eid] || params[:id]}',#{Club.other.id})}
    clubs = Club.named.all(:order => 'LOWER(name)').map{|c| [c.name, c.id]}
    clubs << [ Club.other.name, Club.other.id ]

    select(:record, :club_id, clubs,
           { :prompt => '- Please select a club -' },
           options)
  end

  def is_team_form_column(record, input_name)
    individual_value = false
    team_value = true
    team_options = form_element_input_options(input_name, Entrant)
    individual_options = team_options.dup
    individual_options[:id] += "_#{pretty_tag_value(individual_value)}"
    individual_options[:onclick] = %Q{showIndividualData('#{params[:eid] || params[:id]}')}
    team_options[:id] += "_#{pretty_tag_value(team_value)}"
    team_options[:onclick] = %Q{showTeamData('#{params[:eid] || params[:id]}')}

    returning String.new do |str|
      str << radio_button(:record, :is_team, individual_value, individual_options)
      str << %Q{<span class="radioLabel">Individual</span>}
      str << radio_button(:record, :is_team, team_value, team_options)
      str << %Q{<span class="radioLabel">Team</span>}
    end
  end

  def region_form_column(record, input_name)
    options = form_element_input_options(input_name, Entrant)
    options[:name] += '[id]'
    countries = Country.selectable.all(:order => 'name')

    returning String.new do |str|
      str << %Q{<select id="#{options[:id]}" name="#{options[:name]}">}
      str << %Q{<option value="">Please select</option>}  if record.region_id.nil?
      str << option_groups_from_collection_for_select(countries,
                                                      'regions_by_name', 'name',
                                                      'id', 'name',
                                                      record.region_id)
      str << '</select>'
    end
  end

end
