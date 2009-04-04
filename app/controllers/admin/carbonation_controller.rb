# -*- coding: utf-8 -*-

class Admin::CarbonationController < AdministrationController

  active_scaffold :carbonation do |config|
    config.actions << :sortable
    config.label = 'Carbonation'

    config.create.label = 'Create Carbonation'
    config.create.link.label = 'New Carbonation'

    config.show.label = 'Show Carbonation'

    config.columns = [ :description ]

    # Required fields
    config.columns[:description].required = true
  end

end
