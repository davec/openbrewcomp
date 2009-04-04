# -*- coding: utf-8 -*-

module Admin::StylesHelper

  def point_qualifier_column(record)
    record.point_qualifier? ? "Yes" : "No"
  end

  def mcab_style_column(record)
    record.mcab_style? ? "Yes" : "No"
  end

  def styleinfo_column(record)
    record.style_info.label
  end

  def optional_classic_style_column(record)
    record.optional_classic_style? ? "Yes" : "No"
  end

  def require_carbonation_column(record)
    record.require_carbonation? ? "Yes" : "No"
  end

  def require_strength_column(record)
    record.require_strength? ? "Yes" : "No"
  end

  def require_sweetness_column(record)
    record.require_sweetness? ? "Yes" : "No"
  end

  def description_url_column(record)
    link_to record.description_url, record.description_url
  end

  def styleinfo_form_column(record, input_name)
    rv = ''
    options = form_element_input_options(input_name, Style)
    StyleInfo.key_value_pairs.each do |s|
      options[:id] += "_#{pretty_tag_value(s[0])}"
      rv << radio_button(:record, :styleinfo, s[0], options)
      rv << %Q{<span class="radioLabel">#{s[1]}</span>}
    end
    rv
  end

  # The override for description_url must be defined here (not in the
  # controller) because the DB column is of type text, which causes AS
  # to generate a textarea.
  def description_url_form_column(record, input_name)
    text_field :record, :description_url,
               form_element_input_options(input_name, Style,
                                          { :class => 'text-input code-input',
                                            :size => 60 })
  end

  def award_form_column(record, input_name)
    options = form_element_input_options(input_name, Style)
    options[:name] += '[id]'
    awards = Award.find(:all,
                        :order => 'category_id, position').collect {|a| [ a.name, a.id ]}
    select :record, :award_id, awards,
           { :prompt => '- Select an award category -' },
           options
  end

end
