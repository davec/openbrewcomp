# -*- coding: utf-8 -*-

class Admin::SweetnessController < AdministrationController

  active_scaffold :sweetness do |config|
    config.actions << :sortable
    config.label = 'Sweetness'

    config.create.label = 'Create Sweetness'
    config.create.link.label = 'New Sweetness'

    # Rather pointless to include the show action since
    # all the data is available in the list view anyway.
    config.actions.exclude :show

    config.columns = [ :description ]

    # Required fields
    config.columns[:description].required = true
  end

end
