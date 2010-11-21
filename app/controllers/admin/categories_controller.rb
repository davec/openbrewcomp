# -*- coding: utf-8 -*-

class Admin::CategoriesController < AdministrationController

  before_filter :update_config, :only => [ :create ]

  cache_sweeper :category_sweeper, :only => [ :create, :update, :destroy ]

  active_scaffold :category do |config|
    config.label = 'Categories'

    config.list.columns = [ :position, :name, :is_public, :awards ]

    config.create.label = 'Create Category'
    config.create.link.label = 'New Category'
    config.create.columns = [ :name, :position, :is_public ]
    config.create.action_after_create = 'awards-nested'

    config.update.columns = [ :name, :position, :is_public ]

    config.show.label = 'Show Category'
    config.show.columns = [ :name, :position, :is_public, :awards ]

    config.columns[:awards].sort = false

    # Label overrides
    config.columns[:position].label = 'BJCP Category'

    # Required fields
    [ :name, :position, :is_public ].each do |f|
      config.columns[f].required = true
    end

    # List config
    config.list.sorting = { :position => :asc }
    config.list.per_page = 99999  # Show all categories on one page

    # UI overrides
    config.columns[:is_public].form_ui = :checkbox
    config.columns[:name].options = { :size => 40, :maxlength => 60 }
    config.columns[:position].options = { :size => 2, :maxlength => 2 }
  end

  protected

    def update_config
      # WARNING: We're abusing action_after_create to open a new styles form.
      # The way we're (ab)using it only works for XHR requests. It should be a
      # controller action, but that doesn't fit with the current design of the form.
      active_scaffold_config.create.action_after_create = request.xhr? ? 'styles-nested' : nil
    end

end
