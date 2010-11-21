# -*- coding: utf-8 -*-

class Admin::EntriesWithStyleinfoController < AdministrationController

  before_filter :update_config

  active_scaffold :entry do |config|
    config.label = 'Entries with Style Information'

    config.list.columns = [ :bottle_code, :registration_code,
                            :category, :style_info ]

    config.search.columns = [ :bottle_code, :registration_code,
                              :category, :style_info ]

    config.update.columns = [ :registration_code, :bottle_code,
                              :name, :style, :base_style, :classic_style,
                              :sweetness, :carbonation, :strength,
                              :style_info, :competition_notes ]

    config.show.label = 'Show Entry'
    config.show.columns = [ :registration_code, :bottle_code,
                            :name, :entrant, :category, :base_category,
                            :carbonation, :strength, :sweetness,
                            :style_info, :competition_notes ]

    config.actions.exclude :create
    config.actions.exclude :delete

    # Disable sorting of the style info column (it's pointless)
    config.columns[:style_info].sort = false

    # Label overrides
    config.columns[:name].label = 'Entry Name'
    #config.columns[:style_info].label = 'Pertinent Style Information<br />(for the judges)'
    config.columns[:competition_notes].label = 'Additional Notes<br />(for the head judge)'

    # Virtual columns
    config.columns << :classic_style
    config.columns[:classic_style].label = 'Base Style'

    config.columns << :registration_code
    config.columns[:registration_code].sort = true
    config.columns[:registration_code].sort_by :sql => "entries.id"
    #config.columns[:registration_code].search_sql = "CAST((extract(year from entries.created_at) * 10000 + entries.id) AS CHAR(8))"  ## Moved to update_config

    config.columns << :category
    config.columns[:category].label = 'Style'
    config.columns[:category].sort = true
    #config.columns[:category].sort_by :sql => "lpad(CAST(styles.bjcp_category AS CHAR(2)), 2, '0') || rpad(styles.bjcp_subcategory, 1, '0')"
    config.columns[:category].sort_by :method => 'category_sort_value'
    config.columns[:category].includes = [ :style ]
    config.columns[:category].search_sql = "(styles.bjcp_category||styles.bjcp_subcategory||' '||styles.name)"

    config.columns << :base_category
    config.columns[:base_category].label = 'Base Style'

    config.columns[:entrant].label = 'Brewer'
    config.columns[:entrant].includes = [ :entrant ]

    # List config
    config.list.sorting = { :registration_code => :asc }
    config.list.per_page = 100

    # UI overrides
    config.columns[:bottle_code].options = { :size => 4, :maxlength => 10, :disabled => true }
    config.columns[:name].options = { :size => 40, :maxlength => 80, :disabled => true }
    config.columns[:style_info].form_ui = :textarea
    config.columns[:style_info].options = { :cols => 60, :rows => 4 }
    config.columns[:competition_notes].form_ui = :textarea
    config.columns[:competition_notes].options = { :cols => 60, :rows => 4 }
  end

  def entrant
    @entrant_id = params[:id]
  end

  protected

    def update_config
      # Required by the Entry model
      Controller.admin_view = true
      Controller.nested_view = nested?

      styleinfo_label = case params[:action]
        when 'index'
          'Style Information'
        else
          'Pertinent Style Information<br />(for the judges)'
        end
      active_scaffold_config.columns[:style_info].label = styleinfo_label

      # Because the sql_* methods are inaccessible at the time the AS config is initialized
      active_scaffold_config.columns[:registration_code].search_sql = "CAST((#{sql_extract_year_from('entries.created_at')} * 10000 + entries.id) AS CHAR(8))"
    end

    def conditions_for_collection
      [ 'style_info is not null' ]
    end

end
