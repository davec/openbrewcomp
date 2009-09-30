# -*- coding: utf-8 -*-

class Admin::RegionsController < AdministrationController

  active_scaffold :region do |config|
    config.label = 'Regions'

    config.list.columns = [ :country, :name, :region_code ]

    config.create.label = 'Create Region'
    config.create.link.label = 'Create New Region'
    config.create.columns = [ :name, :region_code, :country ]

    config.update.columns = [ :name, :region_code, :country ]

    config.show.label = 'Show Region'
    config.show.columns = [ :name, :region_code, :country ]

    config.columns[:country].includes = [ :country ]
    config.columns[:country].sort_by :sql => 'countries.name'
    config.columns[:country].clear_link

    # Label overrides
    config.columns[:name].label = 'Region Name'

    # Required fields
    config.columns[:region_code].required = true
    config.columns[:name].required = true
    config.columns[:country].required = true

    # List config
    #config.list.sorting = [ { :country => :asc }, { :name => :asc } ]
    config.list.per_page = 100

    # UI overrides
    config.columns[:name].options = { :size => 40, :maxlength => 60 }
    config.columns[:region_code].options = { :size => 4, :maxlength => 4 }
  end

end
