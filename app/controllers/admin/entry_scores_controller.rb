# -*- coding: utf-8 -*-

class Admin::EntryScoresController < AdministrationController

  before_filter :update_config

  active_scaffold :entry do |config|
    config.list.columns = [ :bottle_code, :place, :avg_score, :scores, :category ]

    config.search.columns = [ :bottle_code, :category ]

    config.show.columns = [ :bottle_code, :category, :place, :avg_score, :scores ]

    config.update.columns = [ :bottle_code, :category, :place, :scores ]

    config.actions.exclude :create
    config.actions.exclude :delete

    # Label overrides
    config.columns[:bottle_code].label = 'Entry'

    # Virtual columns
    config.columns << :avg_score
    config.columns[:avg_score].includes = [ :scores ]
    config.columns[:avg_score].sort = true
    config.columns[:avg_score].sort_by :method => 'avg_score_sort_value'

    config.columns << :category
    config.columns[:category].sort = true
    #config.columns[:category].sort_by :sql => "lpad(CAST(styles.bjcp_category AS CHAR(2)), 2, '0') || rpad(styles.bjcp_subcategory, 1, '0')"
    config.columns[:category].includes = [ :style ]

    # Field sorting options
    config.columns[:place].sort_by :sql => "COALESCE(place,9)" # Force non-placing entries at the end
    config.columns[:scores].sort = false # Sorting the scores column is rather pointless

    # List config
    config.list.sorting = { :bottle_code => :asc }
    config.list.per_page = 100
  end

  def index
    @awards = get_awards
  end

  protected

    def update_config
      @is_full_list = active_scaffold_conditions.nil? && !nested?
      Controller.admin_view = true  # So the entry records can be updated
      Controller.nested_view = nested?
      Controller.label = :bottle_code  # Override the attr used for #to_label

      if @is_full_list
        active_scaffold_config.label = 'Entries'
        active_scaffold_config.theme = :blue
      else
        active_scaffold_config.label = params[:award] || '(Unknown)'
        active_scaffold_config.theme = :default
      end

      # Because the sql_* methods are inaccessible at the time the AS config is initialized
      active_scaffold_config.columns[:category].sort_by :sql => "(#{sql_lpad('CAST(bjcp_category AS CHAR(2))', 2, '0')} || #{sql_rpad('bjcp_subcategory', 1, '0')})"
    end


    def search_authorized?
      @is_full_list
    end

    def conditions_for_collection
      [ 'bottle_code is not null' ]
    end

    def do_update
      unless params[:record][:scores].nil?
        params[:record][:scores].delete_if{|key,value| value[:score].blank?}
        params[:record].delete(:scores) if params[:record][:scores].empty?
      end
      super
    end

  private

    def get_awards
      categories = Category.find(:all,
                                 :include => [ :awards, :styles ],
                                 :conditions => [ 'categories.is_public = ?', true ],
                                 :order => 'categories.position, awards.position')
      categories.inject([]){|arr,c| arr << c.awards}.flatten
    end

end
