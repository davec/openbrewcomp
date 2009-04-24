# -*- coding: utf-8 -*-

class Admin::StylesController < AdministrationController

  before_filter :update_config

  cache_sweeper :style_sweeper, :only => [ :create, :update, :destroy ]

  active_scaffold :style do |config|
    config.label = 'Styles'

    config.list.columns = [ :name, :category,
                            :point_qualifier, :mcab_style,
                            :styleinfo, :require_sweetness,
                            :require_carbonation, :require_strength ]

    config.create.label = 'Create Style'
    config.create.link.label = 'New Style'
    config.create.columns = [ :name, :bjcp_category, :bjcp_subcategory,
                              :award, :description_url,
                              :point_qualifier, :mcab_style,
                              :styleinfo, :require_sweetness,
                              :require_carbonation, :require_strength ]

    config.update.columns = [ :name, :bjcp_category, :bjcp_subcategory,
                              :award, :description_url,
                              :point_qualifier, :mcab_style,
                              :styleinfo, :require_sweetness,
                              :require_carbonation, :require_strength ]

    config.show.label = 'Show Style'
    config.show.columns = [ :name, :category, :award,
                            :description_url,
                            :point_qualifier, :mcab_style,
                            :styleinfo, :require_sweetness,
                            :require_carbonation, :require_strength ]

    # Label overrides
    config.columns[:bjcp_category].label = 'BJCP Category'
    config.columns[:bjcp_subcategory].label = 'BJCP Subcategory'
    config.columns[:description_url].label = 'Description URL'
    config.columns[:mcab_style].label = 'MCAB QS'
    config.columns[:styleinfo].label = 'Style Info'
    config.columns[:require_carbonation].label = 'Require Carbonation Level'
    config.columns[:require_strength].label = 'Require Strength Level'
    config.columns[:require_sweetness].label = 'Require Sweetness Level'

    # Required fields
    [ :name, :bjcp_category, :bjcp_subcategory, :description_url,
      :point_qualifier, :mcab_style, :styleinfo, :require_sweetness,
      :require_carbonation, :require_strength, :award ].each do |f|
      config.columns[f].required = true
    end

    # Virtual fields
    config.columns << :category
    config.columns[:category].sort = true
    #config.columns[:category].sort_by :sql => "(lpad(CAST(bjcp_category AS CHAR(2)), 2, '0') || rpad(bjcp_subcategory, 1, '0'))"  ## Moved to update_config
    config.list.sorting.add :category, :asc

    # List config
    config.list.per_page = 99999  # Show all styles on one page

    # UI overrides
    config.columns[:name].options = { :size => 40, :maxlength => 60 }
    config.columns[:bjcp_category].options = { :size => 2, :maxlength => 2 }
    config.columns[:bjcp_subcategory].options = { :size => 1, :maxlength => 1 }
    config.columns[:point_qualifier].form_ui = :checkbox
    config.columns[:mcab_style].form_ui = :checkbox
    config.columns[:optional_classic_style].form_ui = :checkbox
    config.columns[:require_carbonation].form_ui = :checkbox
    config.columns[:require_strength].form_ui = :checkbox
    config.columns[:require_sweetness].form_ui = :checkbox
  end

  protected

    def update_config
      # Because the sql_* methods are inaccessible at the time the AS config is initialized
      active_scaffold_config.columns[:category].sort_by :sql => "(#{sql_lpad('CAST(bjcp_category AS CHAR(2))', 2, '0')} || #{sql_rpad('bjcp_subcategory', 1, '0')})"
    end

    def do_new
      super
      # Initialize some values based on the parent record
      if @record.award
        @record.bjcp_category = @record.award.category.position
        @record.point_qualifier = @record.award.point_qualifier
      end
    end

end
