# -*- coding: utf-8 -*-

class Admin::RolesController < AdministrationController

  active_scaffold :role do |config|
    config.label = 'Roles'

    config.list.columns = [ :name, :description, :rights ]
    config.list.per_page = 99999  # Show all roles on one page

    config.create.label = 'New Role'
    config.create.link.label = 'New Role'
    config.create.columns = [ :name, :description, :rights, :users ]

    config.update.columns = [ :name, :description, :rights, :users ]

    config.show.label = 'Show Role'

    config.columns[:rights].sort = false

    config.columns[:rights].collapsed = true
    config.columns[:users].collapsed = true

    config.columns[:rights].form_ui = :select
    config.columns[:users].form_ui = :select
  end

end
