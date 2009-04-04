# -*- coding: utf-8 -*-

module Admin::CountriesHelper

  def is_selectable_column(record)
    record.is_selectable? ? "Yes" : "No"
  end

  def regions_column(record)
    if record.regions.blank?
      '-'
    else
      regions = record.regions.sort_by(&:name).collect(&:to_label)
      if controller.action_name == 'show'
        h(regions.join("\n")).gsub("\n",'<br />')
      else
        num_to_show = 3
        regions[num_to_show] = '…' if regions.length > num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
        h(regions.first(num_to_show+1).join(', '))
      end
    end
  end

  def region_name_optional_column(record)
    record.region_name_optional ? "Yes" : "No"
  end

  def address_alignment_column(record)
    address_alignment_label record.address_alignment
  end

  def address_alignment_form_column(record, input_name)
    rv = ''
    options = form_element_input_options(input_name, Country)
    [ 'l', 'c', 'r' ].each do |t|
      options[:id] += "_#{t}"
      rv << radio_button(:record, :address_alignment, t, options)
      rv << %Q{<span class="radioLabel">#{address_alignment_label(t)}</span>}
    end
    rv
  end

  private

    def address_alignment_label(tag)
      case tag
        when 'l', 'L' : "Left"
        when 'r', 'R' : "Right"
        when 'c', 'C' : "Center"
        else            "Unknown"
      end
    end

end
