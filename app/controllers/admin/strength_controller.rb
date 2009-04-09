# -*- coding: utf-8 -*-

class Admin::StrengthController < AdministrationController

  active_scaffold :strength do |config|
    config.actions << :sortable
    config.label = 'Strength'

    config.create.label = 'Create Strength'
    config.create.link.label = 'New Strength'

    # Rather pointless to include the show action since
    # all the data is available in the list view anyway.
    config.actions.exclude :show

    config.columns = [ :description ]

    # Required fields
    config.columns[:description].required = true
  end

end
