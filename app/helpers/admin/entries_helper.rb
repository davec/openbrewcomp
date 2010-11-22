# -*- coding: utf-8 -*-

module Admin::EntriesHelper

  SUBCATS = [ '', 'A', 'B', 'C', 'D', 'E', 'F' ].freeze

  def odd_bottle_column(record)
    record.checked_in? ? (record.odd_bottle? ? 'Yes' : 'No') : '-'
  end

  def checked_in_column(record)
    record.checked_in? ? 'Yes' : 'No'
  end

  def style_info_column(record)
    record.style_info.blank? ? '-' : h(record.style_info).gsub("\n", '<br />')
  end

  def competition_notes_column(record)
    record.competition_notes.blank? ? '-' : h(record.competition_notes).gsub("\n", '<br />')
  end

  def entrant_column(record)
    link_to(h(record.entrant.name), entrant_admin_entry_path(record.entrant), :popup => true)
  end

  def flights_column(record)
    # Don't display any "pushed" flights
    record.flights.reject(&:pushed?).map(&:to_label).join(', ')
  end

  def registration_code_form_column(record, input_name)
    %Q{<span class="readonly">#{record.registration_code}</span>}
  end

  def style_form_column(record, input_name)
    style_form_column_select(input_name, :column => record.style)
  end

  def base_style_id_form_column(record, input_name = true)
    base_style_form_column(record, input_name, false)
  end

  def base_style_form_column(record, input_name, append_id)
    style_form_column_select(input_name, :column => record.base_style,
                                         :conditions => 'bjcp_category <= 28',
                                         :append_id => append_id)
  end

  def classic_style_id_form_column(record, input_name)
    classic_style_form_column(record, input_name, false)
  end

  def classic_style_form_column(record, input_name, append_id = true)
    style_form_column_select(input_name, :column => record.classic_style,
                                         :conditions => 'bjcp_category < 20',
                                         :prompt => 'None',
                                         :extended_option_values => false,
                                         :append_id => append_id)
  end

  def carbonation_form_column(record, input_name)
    options = form_element_input_options(input_name, Entry)
    returning String.new do |str|
      Carbonation.all(:order => 'position').each do |c|
        options[:id] += "_#{pretty_tag_value(c.id)}"
        str << radio_button(:record, :carbonation_id, c.id, options)
        str << %Q{<span class="radioLabel">#{c.description}</span>}
      end
    end
  end

  def strength_form_column(record, input_name)
    options = form_element_input_options(input_name, Entry)
    returning String.new do |str|
      Strength.all(:order => 'position').each do |s|
        options[:id] += "_#{pretty_tag_value(s.id)}"
        str << radio_button(:record, :strength_id, s.id, options)
        str << %Q{<span class="radioLabel">#{s.description}</span>}
      end
    end
  end

  def sweetness_form_column(record, input_name)
    options = form_element_input_options(input_name, Entry)
    returning String.new do |str|
      Sweetness.all(:order => 'position').each do |s|
        options[:id] += "_#{pretty_tag_value(s.id)}"
        str << radio_button(:record, :sweetness_id, s.id, options)
        str << %Q{<span class="radioLabel">#{s.description}</span>}
      end
    end
  end

  private

    def style_option_label(style)
      "#{style.bjcp_category}#{style.bjcp_subcategory} – #{style.name}"
    end

    def style_option_value(style, extended = false)
      return nil unless style
      value = [ "#{style.id}" ]
      if extended
        value << "#{style.bjcp_category.to_i * 100 + SUBCATS.index(style.bjcp_subcategory)}"
        value << (style.optional_classic_style? ? 't' : 'f')
        value << style.styleinfo
        value << (style.require_carbonation? ? 't' : 'f')
        value << (style.require_strength? ? 't' : 'f')
        value << (style.require_sweetness? ? 't' : 'f')
      end
      value.join(',')
    end

    def style_form_column_select(input_name, options = {})
      select_options = form_element_input_options(input_name, Entry)
      select_options[:name] += '[id]' if options[:append_id]
      select_options[:onchange] = %Q{showStyleParams('#{[ params[:eid], params[:id] ].compact.join("_")}')}
      styles = Style.all(:conditions => options[:conditions],
                         :order => 'bjcp_category, bjcp_subcategory').map {
        |s| [ style_option_label(s), style_option_value(s, options[:extended_option_values] || true) ]
      }
      select :record, :style_id, styles,
             { :prompt => options[:prompt] || '- Please select a style -',
               :selected => style_option_value(options[:column], options[:extended_option_values] || true) },
             select_options
    end

end
