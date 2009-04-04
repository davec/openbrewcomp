# -*- coding: utf-8 -*-

class Admin::StrengthController < AdministrationController

  active_scaffold :strength do |config|
    config.actions << :sortable
    config.label = 'Strength'

    config.create.label = 'Create Strength'
    config.create.link.label = 'New Strength'

    config.show.label = 'Show Strength'

    config.columns = [ :description ]

    # Required fields
    config.columns[:description].required = true
  end

end
