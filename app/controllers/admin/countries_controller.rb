# -*- coding: utf-8 -*-

class Admin::CountriesController < AdministrationController

  active_scaffold :country do |config|
    config.label = 'Countries'

    config.list.columns = [ :name, :country_code, :is_selectable, :regions ]

    config.create.label = 'Create Country'
    config.create.link.label = 'New Country'
    config.create.columns = [ :name, :country_code, :is_selectable,
                              :postcode_pattern, :postcode_canonify,
                              :address_format, :address_alignment,
                              :country_address_name, :region_name,
                              :region_name_optional, :regions ]

    config.update.columns = [ :name, :country_code, :is_selectable,
                              :postcode_pattern, :postcode_canonify,
                              :address_format, :address_alignment,
                              :country_address_name, :region_name,
                              :region_name_optional, :regions ]

    config.show.label = 'Show Country'
    config.show.columns = [ :name, :country_code, :is_selectable,
                            :postcode_pattern, :postcode_canonify,
                            :address_format, :address_alignment,
                            :country_address_name, :region_name,
                            :region_name_optional, :regions ]

    config.columns[:regions].collapsed = true

    # Exclusions
    config.create.columns.exclude :entrants
    config.update.columns.exclude :entrants

    # Label overrides
    config.columns[:name].label = 'Country Name'

    # Required fields
    config.columns[:country_code].required = true
    config.columns[:name].required = true
    config.columns[:is_selectable].required = true

    # List config
    config.list.sorting = [ { :is_selectable => :desc }, { :name => :asc } ]
    config.list.per_page = 100

    # UI overrides
    config.columns[:is_selectable].form_ui = :checkbox
    config.columns[:region_name_optional].form_ui = :checkbox
    config.columns[:name].options = { :size => 40, :maxlength => 80 }
    config.columns[:country_code].options = { :size => 2, :maxlength => 2 }
    config.columns[:postcode_pattern].options = { :size => 40, :maxlength => 255, :class => 'code-input' }
    config.columns[:postcode_canonify].options = { :size => 40, :maxlength => 255, :class => 'code-input' }
    config.columns[:address_format].options = { :size => 40, :maxlength => 255, :class => 'code-input' }
    config.columns[:country_address_name].options = { :size => 20, :maxlength => 60 }
    config.columns[:region_name].options = { :size => 20, :maxlength => 20 }
  end

end
