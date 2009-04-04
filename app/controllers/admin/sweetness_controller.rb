# -*- coding: utf-8 -*-

class Admin::SweetnessController < AdministrationController

  active_scaffold :sweetness do |config|
    config.actions << :sortable
    config.label = 'Sweetness'

    config.create.label = 'Create Sweetness'
    config.create.link.label = 'New Sweetness'

    config.show.label = 'Show Sweetness'

    config.columns = [ :description ]

    # Required fields
    config.columns[:description].required = true
  end

end
