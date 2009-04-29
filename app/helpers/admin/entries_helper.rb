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
    record.flights.reject{|f| f.send(:pushed?)}.collect{|f| h(f.to_label)}
  end

  def registration_code_form_column(record, input_name)
    %Q{<span class="readonly">#{record.registration_code}</span>}
  end

  def style_form_column(record, input_name)
    options = form_element_input_options(input_name, Entry)
    options[:name] += '[id]'
    options[:onchange] = "showStyleParams('#{params[:eid] || params[:id]}')"
    styles = Style.find(:all,
                        :order => 'bjcp_category, bjcp_subcategory').collect {
      |s| [ style_option_label(s), style_option_value(s, true) ]
    }
    select :record, :style_id, styles,
           { :prompt => '- Please select a style -',
             :selected => record.style.nil? ? nil : style_option_value(record.style, true) },
           options
  end

  def base_style_form_column(record, input_name)
    base_style_form_column(record, input_name, true)
  end

  def base_style_id_form_column(record, input_name)
    base_style_form_column(record, input_name, false)
  end

  def base_style_form_column(record, input_name, append_id)
    options = form_element_input_options(input_name, Entry)
    options[:name] += '[id]' if append_id
    options[:onchange] = "showStyleParams('#{params[:eid] || params[:id]}')"
    styles = Style.find(:all,
                        :conditions => 'bjcp_category <= 28',
                        :order => 'bjcp_category, bjcp_subcategory').collect {
      |s| [ style_option_label(s), style_option_value(s, true) ]
    }
    select :record, :base_style_id, styles,
           { :prompt => '- Please select a style -',
             :selected => record.base_style.nil? ? nil : style_option_value(record.base_style, true) },
           options
  end

  def classic_style_form_column(record, input_name)
    classic_style_form_column(record, input_name, true)
  end

  def classic_style_id_form_column(record, input_name)
    classic_style_form_column(record, input_name, false)
  end

  def classic_style_form_column(record, input_name, append_id)
    options = form_element_input_options(input_name, Entry)
    options[:name] += '[id]' if append_id
    options[:onchange] = "showStyleParams('#{params[:eid] || params[:id]}')"
    styles = Style.find(:all,
                        :conditions => 'bjcp_category < 20',
                        :order => 'bjcp_category, bjcp_subcategory').collect {
      |s| [ style_option_label(s), style_option_value(s) ]
    }
    select :record, :classic_style_id, styles,
           { :prompt => 'None',
             :selected => record.classic_style.nil? ? nil : style_option_value(record.classic_style) },
           options
  end

  def carbonation_form_column(record, input_name)
    rv = ''
    options = form_element_input_options(input_name, Entry)
    Carbonation.find(:all, :order => 'position').each do |c|
      options[:id] += "_#{pretty_tag_value(c.id)}"
      rv << radio_button(:record, :carbonation_id, c.id, options)
      rv << %Q{<span class="radioLabel">#{c.description}</span>}
    end
    rv
  end

  def strength_form_column(record, input_name)
    rv = ''
    options = form_element_input_options(input_name, Entry)
    Strength.find(:all, :order => 'position').each do |s|
      options[:id] += "_#{pretty_tag_value(s.id)}"
      rv << radio_button(:record, :strength_id, s.id, options)
      rv << %Q{<span class="radioLabel">#{s.description}</span>}
    end
    rv
  end

  def sweetness_form_column(record, input_name)
    rv = ''
    options = form_element_input_options(input_name, Entry)
    Sweetness.find(:all, :order => 'position').each do |s|
      options[:id] += "_#{pretty_tag_value(s.id)}"
      rv << radio_button(:record, :sweetness_id, s.id, options)
      rv << %Q{<span class="radioLabel">#{s.description}</span>}
    end
    rv
  end

  private

    def style_option_label(style)
      "#{style.bjcp_category}#{style.bjcp_subcategory} – #{style.name}"
    end

    def style_option_value(style, extended=false)
      value = "#{style.id}"
      if extended
        value << ",#{style.bjcp_category.to_i * 100 + SUBCATS.index(style.bjcp_subcategory)}"
        value << ",#{style.optional_classic_style? ? 't' : 'f'}"
        value << ",#{style.styleinfo}"
        value << ",#{style.require_carbonation? ? 't' : 'f'}"
        value << ",#{style.require_strength? ? 't' : 'f'}"
        value << ",#{style.require_sweetness? ? 't' : 'f'}"
      end
      value
    end

end
