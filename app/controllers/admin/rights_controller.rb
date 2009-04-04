# -*- coding: utf-8 -*-

class Admin::RightsController < AdministrationController

  active_scaffold :right do |config|
    config.label = 'Rights'

    config.list.columns = [ :name, :description, :controller, :action ]
    config.list.per_page = 99999  # Show all roles on one page

    config.create.label = 'Create Right'
    config.create.link.label = 'New Right'
    config.create.columns = [ :name, :description, :controller, :action ]

    config.update.columns = [ :name, :description, :controller, :action ]

    config.show.label = 'Show Right'
  end

end
