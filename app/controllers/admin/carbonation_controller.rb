# -*- coding: utf-8 -*-

class Admin::CarbonationController < AdministrationController

  active_scaffold :carbonation do |config|
    config.actions << :sortable
    config.label = 'Carbonation'

    config.create.label = 'Create Carbonation'
    config.create.link.label = 'New Carbonation'

    # Rather pointless to include the show action since
    # all the data is available in the list view anyway.
    config.actions.exclude :show

    config.columns = [ :description ]

    # Required fields
    config.columns[:description].required = true
  end

end
