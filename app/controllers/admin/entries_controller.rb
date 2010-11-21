# -*- coding: utf-8 -*-

class Admin::EntriesController < AdministrationController

  before_filter :update_config, :except => :bottle_labels

  active_scaffold :entry do |config|
    config.label = 'Entries'

    config.list.columns = [ :bottle_code, :registration_code,
                            :category, :name, :flights ]

    config.search.columns = [ :bottle_code, :registration_code,
                              :category, :name ]

    config.create.label = 'Create Entry'
    config.create.link.label = 'Add An Entry'
    config.create.columns = [ :bottle_code, :odd_bottle,
                              :name, :style, :base_style_id, :classic_style_id,
                              :sweetness, :carbonation, :strength,
                              :style_info, :competition_notes ]

    config.update.columns = [ :registration_code, :bottle_code, :odd_bottle,
                              :name, :style, :base_style_id, :classic_style_id,
                              :sweetness, :carbonation, :strength,
                              :style_info, :competition_notes ]

    config.show.label = 'Show Entry'
    config.show.columns = [ :registration_code, :bottle_code, :checked_in, :odd_bottle,
                            :name, :entrant, :category, :base_category,
                            :carbonation, :strength, :sweetness,
                            :style_info, :competition_notes, :flights ]

    # Sorting on the flights column isn't particularly useful (what's the sort criteria anyway?)
    config.columns[:flights].sort = false

    # Subform columns updated in the flights controller.
    # This list is different between each round (second_round is set in
    # first-round flights, place in second-round flights, and mcab_qe and
    # bos_place in the BOS flights), but I don't think we can set the
    # subform columns dynamically, so they are all configured here.
    config.subform.columns = [ :second_round, :place, :mcab_qe, :bos_place ]

    # Additional actions
    #
    # Print an individual bottle label.
    # NOTE: The value of crud_type is set to 'print' even though it isn't really
    # a valid value for crud_type.  The model's authorized_for? method must
    # handle it specifically.  The alternative is to confuse matters by setting
    # the value of crud_type to :update, even though it's really :read, so that
    # the authorized_for_#{crud_type} method returns the expected value for the
    # print links.
    config.action_links.add 'print',
                            :label=> 'Print',
                            :type => :member,
                            :action => 'print',
                            :crud_type => 'print',
                            :popup => true

    # Add a help link
    config.action_links.add 'help',
                            :label => 'Help',
                            :type => :collection,
                            :action => 'help',
                            :inline => true,
                            :position => :top,
                            :popup => false

    # Label overrides
    config.columns[:name].label = 'Entry Name'
    config.columns[:style_info].label = 'Pertinent Style Information<br />(for the judges)'
    config.columns[:competition_notes].label = 'Additional Notes<br />(for the head judge)'

    #config.columns[:carbonation].description = 'Required for meads and ciders'
    #config.columns[:strength].description = 'Required for meads and ciders'
    #config.columns[:sweetness].description = 'Required for meads and ciders'
    #config.columns[:style_info].description = 'Required for categories 16E, 17F, 20, 21A, 23, 26A, 26C, 28A, 28B, 28D, and 29; optional for all other categories.'
    #config.columns[:competition_notes].description = 'Additional notes to be added during entry processing, if necessary.'

    # Virtual columns
    config.columns << :classic_style_id
    config.columns[:classic_style_id].label = 'Base Style'
    config.columns[:base_style_id].label = 'Base Style'

    config.columns << :registration_code
    config.columns[:registration_code].sort = true
    config.columns[:registration_code].sort_by :sql => 'entries.id'
    #config.columns[:registration_code].search_sql = "CAST((extract(year from entries.created_at) * 10000 + entries.id) AS CHAR(8))" ## Moved to udpate_config

    config.columns << :category
    config.columns[:category].label = 'Style'
    config.columns[:category].sort = true
    #config.columns[:category].sort_by :sql => "lpad(CAST(styles.bjcp_category AS CHAR(2)), 2, '0') || rpad(styles.bjcp_subcategory, 1, '0')"
    config.columns[:category].sort_by :method => 'category_sort_value'
    config.columns[:category].includes = [ :style ]
    config.columns[:category].search_sql = "(styles.bjcp_category||styles.bjcp_subcategory||' '||styles.name)"

    config.columns << :base_category
    config.columns[:base_category].label = 'Base Style'

    config.columns << :checked_in
    config.columns[:checked_in].label = 'Checked In'

    config.columns[:entrant].label = 'Brewer'
    config.columns[:entrant].includes = [ :entrant ]
    #config.columns[:entrant].sort = true
    #config.columns[:entrant].sort_by :sql => '(entrants.last_name||entrants.middle_name||entrants.first_name||entrants.team_name)'
    #config.columns[:entrant].search_sql = "(entrants.first_name||' '||entrants.middle_name||' '||entrants.last_name||' '||entrants.team_name)"

    config.columns[:name].sort_by :sql => 'lower(entries.name)'

    config.list.sorting = { :registration_code => :asc }

    # UI overrides
    config.columns[:odd_bottle].form_ui = :checkbox
    config.columns[:bottle_code].options = { :size => 4, :maxlength => 10 }
    config.columns[:name].options = { :size => 40, :maxlength => 80 }
    config.columns[:style_info].form_ui = :textarea
    config.columns[:style_info].options = { :cols => 60, :rows => 4 }
    config.columns[:competition_notes].form_ui = :textarea
    config.columns[:competition_notes].options = { :cols => 60, :rows => 4 }
  end

  def print
    id = params[:id]
    @entry = Entry.find(id)
    @num_labels_to_print = @entry.style.number_of_bottles_required
    @competition_name = competition_name
    render :layout => 'layouts/simple'
  end

  def help
    render :partial => 'help'
  end

  def bottle_labels
    @entries = current_user.entries.find(:all,
                                         :include => [ :entrant, :style ],
                                         :conditions => [ 'bottle_code IS NULL' ],
                                         :order => 'entrants.id, entries.id')
    unless @entries.empty?
      @competition_name = competition_name
      render_pdf 'bottle_labels.pdf'
    else
      # We should not normally get here since the 'Print All' link should be
      # hidden if no entries have been registered.
      flash[:error] = 'You have not registered any entries'
      request.env['HTTP_REFERER'] ? redirect_to(:back) : redirect_to(online_registration_url)
    end
  end

  def entrant
    @entrant_id = params[:id]
  end

  protected

    def do_new
      raise ActionController::MethodNotAllowed unless create_authorized?
      super
    end

    def do_create
      raise ActionController::MethodNotAllowed unless create_authorized?
      [ :base_style_id, :classic_style_id ].each do |param|
        params[:record].delete(param) if params[:record][param].blank?
      end
      super
    end

    def do_update
      params[:record].delete(:classic_style_id) if params[:record][:classic_style_id].blank?
      params[:record].delete(:base_style_id) if params[:record][:base_style_id].blank?
      super
    end

    def do_destroy
      super
      @entry_count = Entry.count(:conditions => [ 'user_id = ?', current_user.id ])
    end

    def before_create_save(record)
      # If the record is created in the admin interface, assign it to the admin
      # user account rather than the user (data entry slave) who creates it.
      # This will keep the data entry slave from seeing entries that are not
      # theirs if they subsequently use the non-admin interface to register
      # their own entries.
      record.user_id = @is_admin_view ? User.admin_id : session[:user_id]
    end

    def create_authorized?
      # Only show the create link if this scaffold is nested
      nested?
    end

    def print_authorized?
      !@is_admin_view
    end

    def find_if_allowed(id, action)
      # Admins can modify and delete an entry regardless of any restrictions that
      # prevent a non-admin from modifying or deleting the entry.
      return Entry.find(id) if @is_admin_view

      begin
        super(id, action)
      rescue
        flash[:error] = "You are not allowed to #{action} entry #{Entry.find(id).registration_code}"
        false
      end
    end

    def authorized?
      @is_admin_view = !params[:parent_model] || !!session[:entrants_admin_view]
      if @is_admin_view && params[:action] != 'bottle_labels'
        super
      else
        logged_in? && (params[:id].nil? ||
                       authorized_for?(Entry.find_by_id(params[:id])))
      end
    end

    def update_config
      Controller.admin_view = @is_admin_view
      Controller.nested_view = nested?
      if @is_admin_view
        active_scaffold_config.list.per_page = nested? ? 25 : 100
        active_scaffold_config.theme = :blue
      else
        active_scaffold_config.list.columns.exclude [ :flights ]
        active_scaffold_config.list.per_page = 99999
        active_scaffold_config.theme = :default
      end

      # Because the sql_* methods are inaccessible at the time the AS config is initialized
      active_scaffold_config.columns[:registration_code].search_sql = "CAST((#{sql_extract_year_from('entries.created_at')} * 10000 + entries.id) AS CHAR(8))"
    end

    def search_authorized?
      @is_admin_view
    end

    def help_authorized?
      !@is_admin_view
    end

end
