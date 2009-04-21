# -*- coding: utf-8 -*-

include GeoKit::Geocoders

class Admin::JudgesController < AdministrationController

  before_filter :update_config
  before_filter :geocode_ip, :only => [ :new ]

  ALL_LIST_COLUMNS = [ :dictionary_name, :judge_rank, :judge_number,
                       :confirmed, :checked_in, :comments, :flights,
                       :staff_points, :steward_points, :judge_points ]
  ADMIN_LIST_COLUMNS = ALL_LIST_COLUMNS
  NON_ADMIN_LIST_COLUMNS = [ :dictionary_name, :judge_rank, :judge_number ]

  ALL_SHOW_COLUMNS = [ :postal_address, :email, :phone, :club,
                       :judge_rank, :judge_number, :time_availabilities,
                       :category_preferences, :comments, :confirmed,
                       :checked_in, :organizer, :role, :staff_points, :points ]
  ADMIN_SHOW_COLUMNS = ALL_SHOW_COLUMNS
  NON_ADMIN_SHOW_COLUMNS = [ :postal_address, :email, :phone, :club,
                             :judge_rank, :judge_number, :time_availabilities,
                             :category_preferences, :comments ]

  active_scaffold :judge do |config|
    config.list.columns = ALL_LIST_COLUMNS

    config.search.columns = [ :dictionary_name, :judge_number ]

    config.create.label = 'Create Judge/Steward'
    config.create.link.label = 'Add A Judge/Steward'
    config.create.columns = [ :first_name, :middle_name, :last_name, :goes_by,
                              :address1, :address2, :address3, :address4,
                              :city, :region, :postcode,
                              :email, :phone, :club, :club_name,
                              :judge_rank, :judge_number, :comments,
                              :time_availabilities, :category_preferences,
                              :confirmed, :checked_in, :organizer ]

    config.update.columns = [ :first_name, :middle_name, :last_name, :goes_by,
                              :address1, :address2, :address3, :address4,
                              :city, :region, :postcode,
                              :email, :phone, :club, :club_name,
                              :judge_rank, :judge_number, :comments,
                              :time_availabilities, :category_preferences,
                              :confirmed, :checked_in, :organizer,
                              :staff_points ]

    config.show.label = 'Show Judge/Steward'
    config.show.columns = ALL_SHOW_COLUMNS

    # Add a help link
    config.action_links.add 'help',
                            :label => 'Help',
                            :type => :table,
                            :action => 'help',
                            :inline => true,
                            :position => :top,
                            :popup => false

    # Label overrides
    config.columns[:first_name].label = 'First Name'
    config.columns[:middle_name].label = 'Middle Name'
    config.columns[:last_name].label = 'Last Name'
    config.columns[:address1].label = 'Address'
    config.columns[:address2].label = ''
    config.columns[:address3].label = ''
    config.columns[:address4].label = ''
    config.columns[:region].label = 'State/Province'
    config.columns[:postcode].label = 'Zip/Postal Code'
    config.columns[:judge_number].label = 'BJCP ID'
    config.columns[:judge_rank].label = 'Judge Rank'
    config.columns[:created_at].label = 'Creation Time'
    config.columns[:updated_at].label = 'Last Update Time'
    config.columns[:flights].label = 'Judged Flights'
    config.columns[:confirmed].label = 'Will Judge'
    config.columns[:checked_in].label = 'Checked&nbsp;In'
    config.columns[:staff_points].label = 'Staff Points'
    config.columns[:time_availabilities].label = 'Available Judging Times'

    # Sorting
    config.columns[:judge_rank].sort_by :sql => 'position'
    config.columns[:judge_rank].clear_link

    # Virtual fields
    config.columns << :club_name

    config.columns << :dictionary_name
    config.columns[:dictionary_name].label = 'Name'
    config.columns[:dictionary_name].sort = true
    config.columns[:dictionary_name].sort_by :sql => "LOWER(last_name||first_name||middle_name)"
    config.columns[:dictionary_name].search_sql = "(first_name||middle_name||last_name)"

    config.columns << :postal_address
    config.columns[:postal_address].label = 'Name and Address'

    config.columns << :points
    config.columns[:points].label = 'Total Points'

    config.columns << :role
    config.columns[:role].label = 'Judge Role'

    config.columns << :steward_points
    config.columns[:steward_points].label = 'Steward Points'
    config.columns[:steward_points].sort = true
    config.columns[:steward_points].sort_by :method => 'steward_points'

    config.columns << :judge_points
    config.columns[:judge_points].label = 'Judge Points'
    config.columns[:judge_points].sort = true
    config.columns[:judge_points].sort_by :method => 'judge_points'

    config.columns << :is_bos_judge
    config.columns[:is_bos_judge].label = 'BOS Judge'
    config.columns[:is_bos_judge].sort = true
    config.columns[:is_bos_judge].sort_by :method => 'bos_judge_sort'

    config.list.sorting = { :dictionary_name => :asc }

    # HACK: Force TimeAvailabilities to be saved; otherwise
    # ActiveScaffold::AttributeParams#attributes_hash_is_empty?
    # decides that since it consists solely of DateTime values
    # it does not need to be saved. (The alternative is to add
    # a dummy column to the table that is not a boolean, date,
    # time, or datetime.)
    config.columns[:time_availabilities].show_blank_record = false

    # UI overrides
    config.columns[:address1].options = { :size => 76, :maxlength => 80 }
    config.columns[:address2].options = { :size => 76, :maxlength => 80 }
    config.columns[:address3].options = { :size => 76, :maxlength => 80 }
    config.columns[:address4].options = { :size => 76, :maxlength => 80 }
    config.columns[:checked_in].form_ui = :checkbox
    config.columns[:checked_in].inplace_edit = true
    config.columns[:city].options = { :size => 25, :maxlength => 80 }
    config.columns[:club_name].options = { :size => 30, :maxlength => 60 }
    config.columns[:comments].options = { :cols => 80, :rows => 8 }
    config.columns[:email].options = { :size => 40, :maxlength => 100 }
    config.columns[:first_name].options = { :size => 25, :maxlength => 80 }
    config.columns[:goes_by].options = { :size => 15, :maxlength => 80 }
    config.columns[:judge_number].options = { :size => 10, :maxlength => 10 }
    config.columns[:last_name].options = { :size => 25, :maxlength => 80 }
    config.columns[:middle_name].options = { :size => 15, :maxlength => 80 }
    config.columns[:organizer].form_ui = :checkbox
    config.columns[:phone].options = { :size => 20, :maxlength => 40 }
    config.columns[:postcode].options = { :size => 10, :maxlength => 20 }
  end

  def row
    # Override the default row so the is_admin_view setting can be applied
    # to the record before it's displayed. Failure to do this can result in
    # the delete action being deactivated.
    record = find_if_allowed(params[:id], :read)
    record.is_admin_view = @is_admin_view unless record.nil?
    render :partial => 'list_record', :locals => {:record => record}
  end

  def help
    render :partial => 'help'
  end

  protected

    def do_list
      super
      # Record the admin view status in each record (required by the model's
      # authorized_for_destroy? method). This seems to be the only way the model
      # can know whether it's being used in an admin view.
      @records.each do |record|
        record.is_admin_view = @is_admin_view
      end
      if @is_admin_view
        @options = {
          # Who is the competition organizer?
          :competition_organizer => (Judge.organizer.name rescue nil),
          # How many staff points remain in the pool?
          :unallocated_staff_points => "%.1f" % Judge.unallocated_staff_points
        }
      end
    end

    def do_new
      super
      if session[:last_region_id]
        @record.region_id = session[:last_region_id]
      elsif session[:geocode_ip]
        geoloc = session[:geocode_ip]
        @record.region_id = Region.find_by_sql(['SELECT id FROM regions WHERE region_code = ? AND country_id = (SELECT id FROM countries WHERE country_code = ? AND is_selectable = ?)', geoloc.state, geoloc.country_code, true])[0].id rescue nil
      end
    end

    def do_edit
      super
      if @is_admin_view
        # How many staff points are available to be assigned to this judge?
        @available_staff_points = "%.1f" % @record.available_staff_points
      end
    end

    def do_update
      super
      if @is_admin_view
        @options = {
          # Who is the competition organizer?
          :competition_organizer => (Judge.organizer.name rescue nil),
          # How many staff points remain in the pool?
          :unallocated_staff_points => "%.1f" % Judge.unallocated_staff_points,
          # How many staff points can be assigned to this judge?
          :available_staff_points => "%.1f" % @record.available_staff_points
        }
      end
    end

    def before_create_save(record)
      # If the record is created in the admin interface, assign it to the admin
      # user account rather than the user (data entry slave) who creates it.
      # This will keep the data entry slave from seeing entries that are not
      # theirs if they subsequently use the non-admin interface to register
      # their own entries.
      record.user_id = @is_admin_view ? User.admin_id : session[:user_id]
    end

    def after_create_save(record)
      session[:last_region_id] = record.region_id
    end

    def authorized?
      @is_admin_view = active_scaffold_constraints[:user_id].nil?
      if @is_admin_view
        super
      else
        logged_in? && (params[:id].nil? ||
                       authorized_for?(Judge.find_by_id(params[:id])))
      end
    end

    def update_config
      Controller.admin_view = @is_admin_view
      active_scaffold_config.list.columns.exclude ALL_LIST_COLUMNS
      active_scaffold_config.show.columns.exclude ALL_SHOW_COLUMNS
      if @is_admin_view
        active_scaffold_config.list.columns.add ADMIN_LIST_COLUMNS
        active_scaffold_config.show.columns.add ADMIN_SHOW_COLUMNS
        active_scaffold_config.columns[:email].label = 'Email'
        active_scaffold_config.columns[:phone].label = 'Phone'
        active_scaffold_config.label = 'Judges, Stewards, and Staff'
        active_scaffold_config.list.per_page = 100
        active_scaffold_config.theme = :blue
      else
        active_scaffold_config.list.columns.add NON_ADMIN_LIST_COLUMNS
        active_scaffold_config.show.columns.add NON_ADMIN_SHOW_COLUMNS
        active_scaffold_config.columns[:email].label = 'Email *'
        active_scaffold_config.columns[:phone].label = 'Phone *'
        active_scaffold_config.label = 'Judges/Stewards'
        active_scaffold_config.list.per_page = 20
        active_scaffold_config.theme = :default
      end
    end

    def geocode_ip
      session[:geocode_ip] ||= begin
        #location = IpGeocoder.geocode(ENV['RAILS_ENV'] == 'development' ? '66.93.40.13' : request.remote_ip)
        location = IpGeocoder.geocode(request.remote_ip)
        location.success ? location : nil
      end
    end

    def search_authorized?
      @is_admin_view
    end

    def help_authorized?
      !@is_admin_view
    end

end
