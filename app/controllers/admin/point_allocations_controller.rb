# -*- coding: utf-8 -*-

class Admin::PointAllocationsController < AdministrationController

  active_scaffold :point_allocations do |config|
    config.columns = [ :min_entries, :max_entries, :organizer, :staff, :judge ]
    config.label = 'Point Allocations (by competition size)'

    config.create.label = 'Create Point Allocation'
    config.create.link.label = 'New Point Allocation'

    config.show.label = 'Show Point Allocation'

    # Label overrides
    config.columns[:min_entries].label = 'Minimum Entries'
    config.columns[:max_entries].label = 'Maximum Entries'
    config.columns[:organizer].label = 'Organizer Points'
    config.columns[:staff].label = 'Staff Points'
    config.columns[:judge].label = 'Judge Points'

    # Column options
    [ :min_entries, :max_entries, :organizer, :staff, :judge ].each do |f|
      config.columns[f].options = { :size => 4, :maxlength => 4, :style => "text-align: right" }
    end

    # Required fields
    [ :min_entries, :max_entries, :organizer, :staff, :judge ].each do |f|
      config.columns[f].required = true
    end

    # List config
    config.list.sorting = { :min_entries => :asc }
    config.list.per_page = 99999 # Show all point allocations on one page
  end

end
