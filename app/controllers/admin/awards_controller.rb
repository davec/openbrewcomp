# -*- coding: utf-8 -*-

class Admin::AwardsController < AdministrationController

  before_filter :update_config, :only => [ :create ]

  cache_sweeper :award_sweeper, :only => [ :create, :update, :destroy ]

  active_scaffold :award do |config|
    config.label = 'Awards'

    config.list.columns = [ :name, :point_qualifier, :category, :styles ]

    config.create.label = 'Create Award'
    config.create.link.label = 'New Award'
    config.create.columns = [ :name, :category, :point_qualifier, :position ]

    config.update.columns = [ :name, :category, :point_qualifier, :position ]

    config.show.label = 'Show Award'
    config.show.columns = [ :name, :category, :styles, :point_qualifier, :position ]

    # Required fields
    [ :name, :category, :point_qualifier, :position ].each do |f|
      config.columns[f].required = true
    end

    # Required fields
    config.columns[:name].required = true

    # Sortable fields
    config.columns[:styles].sort = false

    # List config
    config.list.sorting = [ { :category_id => :asc }, { :position => :asc } ]
    config.list.per_page = 99999  # Show all awards on one page

    # UI overrides
    config.columns[:point_qualifier].form_ui = :checkbox
    config.columns[:name].options = { :size => 40, :maxlength => 60 }
    config.columns[:position].options = { :size => 2, :maxlength => 2 }

    config.columns[:category].clear_link
  end

  protected

    def do_new
      super
      @record.position = 1
      @record.position += @record.category.awards.length if @record.category
    end

    def update_config
      # WARNING: We're abusing action_after_create to open a new styles form.
      # The way we're (ab)using it only works for XHR requests. It should be a
      # controller action, but that doesn't fit with the current design of the form.
      active_scaffold_config.create.action_after_create = request.xhr? ? 'styles-nested' : nil
    end
end
