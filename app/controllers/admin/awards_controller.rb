# -*- coding: utf-8 -*-

class Admin::AwardsController < AdministrationController

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
  end

end
