# -*- coding: utf-8 -*-

module Admin::CountriesHelper

  def is_selectable_column(record)
    record.is_selectable? ? "Yes" : "No"
  end

  def regions_column(record)
    return '-' if record.regions.blank?

    num_to_show = 3
    regions = sorted_regions(record).first(num_to_show+1).map(&:to_label)
    regions[num_to_show] = '…' if regions.length > num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
    h(regions.join(', '))
  end

  def regions_show_column(record)
    return '-' if record.regions.blank?
    sorted_regions(record).map{|r| h(r.to_label)}.join('<br />')
  end

  def region_name_optional_column(record)
    record.region_name_optional ? "Yes" : "No"
  end

  def address_alignment_column(record)
    address_alignment_label record.address_alignment
  end

  def address_alignment_form_column(record, input_name)
    options = form_element_input_options(input_name, Country)
    returning String.new do |str|
      %w(l c r).each do |t|
        options[:id] += "_#{t}"
        str << radio_button(:record, :address_alignment, t, options)
        str << %Q{<span class="radioLabel">#{address_alignment_label(t)}</span>}
      end
    end
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

    def sorted_regions(record)
      record.regions.sort
    end

end
