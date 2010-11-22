# -*- coding: utf-8 -*-

module Admin::RegionsHelper

  def country_form_column(record, input_name)
    options = form_element_input_options(input_name, Region)
    options[:name] += '[id]'
    countries = Country.all(:order => 'name').map {|c| [c.name, c.id]}
    select :record, :country_id, countries,
           { :prompt => '- Please select a country -' },
           options
  end

end
