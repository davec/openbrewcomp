# -*- coding: utf-8 -*-

class Admin::RoundsController < AdministrationController

  active_scaffold :rounds do |config|
    config.actions << :sortable
    config.label = 'Rounds'

    config.create.label = 'Create Round'
    config.create.link.label = 'New Round'

    config.show.label = 'Show Round'

    # Exclusions
    config.create.columns.exclude [ :flights ]
    config.update.columns.exclude [ :flights ]

    # Sorting
    config.columns[:flights].sort = false

    # Required fields
    config.columns[:name].required = true
  end

end
