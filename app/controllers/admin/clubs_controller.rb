# -*- coding: utf-8 -*-

class Admin::ClubsController < AdministrationController

  active_scaffold :club do |config|
    config.label = 'Clubs'

    config.list.columns = [ :name ]

    config.create.label = 'Create Club'
    config.create.link.label = 'New Club'

    config.show.label = 'Show Club'
    config.show.columns = [ :name ]

    # Exclusions
    config.create.columns.exclude [ :entrants, :entries ]
    config.update.columns.exclude [ :entrants, :entries ]

    # Required fields
    config.columns[:name].required = true

    # Field sort options
    config.columns[:name].sort_by :sql => 'lower(name)'

    # List config
    config.list.sorting = { :name => :asc }
    config.list.per_page = 100

    # UI overrides
    config.columns[:name].options = { :size => 60, :maxlength => 60 }
  end

end
