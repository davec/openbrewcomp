# -*- coding: utf-8 -*-

class Admin::ContactsController < AdministrationController

  cache_sweeper :contact_sweeper, :only => [ :create, :update, :destroy ]

  active_scaffold :contact do |config|
    config.label = 'Contacts'

    config.list.columns = [ :role, :name, :email, :updated_at ]

    config.create.label = 'Create Contact'
    config.create.link.label = 'New Contact'
    config.create.columns = [ :role, :name, :email ]

    config.update.columns = [ :role, :name, :email ]

    config.show.label = 'Show Contact'
    config.show.columns = [ :role, :name, :email, :updated_at ]

    # Label overrides
    config.columns[:created_at].label = 'Creation Time'
    config.columns[:updated_at].label = 'Last Update Time'

    # Required fields
    config.columns[:role].required = true
    config.columns[:name].required = true
    config.columns[:email].required = true

    # List config
    config.list.sorting = { :role => :asc }
    config.list.per_page = 99999  # Show all contacts on one page

    # UI overrides
    config.columns[:role].options = { :size => 20, :maxlength => 40 }
    config.columns[:name].options = { :size => 20, :maxlength => 80 }
    config.columns[:email].options = { :size => 30, :maxlength => 80, :class => 'code-input' }
  end

end
