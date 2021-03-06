# -*- coding: utf-8 -*-

include GeoKit::Geocoders

class Admin::EntrantsController < AdministrationController

  before_filter :update_config
  before_filter :geocode_ip, :only => [ :new ]

  active_scaffold :entrant do |config|
    config.label = 'Brewers'

    config.list.columns = [ :dictionary_name, :is_team, :club, :entries ]

    config.search.columns = [ :dictionary_name, :club ]

    config.create.label = 'Create Brewer'
    config.create.link.label = 'Add A Brewer'
    config.create.columns = [ :is_team, :team_name, :team_members,
                              :first_name, :middle_name, :last_name,
                              :address1, :address2, :address3, :address4,
                              :city, :region, :postcode,
                              :email, :phone, :club, :club_name, :entries ]

    config.update.columns = [ :is_team, :team_name, :team_members,
                              :first_name, :middle_name, :last_name,
                              :address1, :address2, :address3, :address4,
                              :city, :region, :postcode,
                              :email, :phone, :club, :club_name, :entries ]

    config.show.label = 'Show Brewer'
    config.show.columns = [ :postal_address, :is_team, :team_members,
                            :email, :phone, :club ]

    config.delete.link.confirm = :are_you_sure_delete_of_entrant

    # Disable sorting of the entries column (it's pointless)
    config.columns[:entries].sort = false

    # Add a help link
    config.action_links.add 'help',
                            :label => 'Help',
                            :type => :collection,
                            :action => 'help',
                            :inline => true,
                            :position => :top,
                            :popup => false

    # Label overrides
    config.columns[:is_team].label = 'Team?'
    config.columns[:first_name].label = 'First Name'
    config.columns[:middle_name].label = 'Middle Name'
    config.columns[:last_name].label = 'Last Name'
    config.columns[:team_name].label = 'Team Name'
    config.columns[:team_members].label = 'Team Members'
    config.columns[:address1].label = 'Address'
    config.columns[:address2].label = ''
    config.columns[:address3].label = ''
    config.columns[:address4].label = ''
    config.columns[:region].label = 'State/Province'
    config.columns[:postcode].label = 'Zip/Postal Code'
    config.columns[:email].label = 'Email *'
    config.columns[:phone].label = 'Phone *'
    config.columns[:created_at].label = 'Creation Time'
    config.columns[:updated_at].label = 'Last Update Time'
    config.columns[:entries].label = ''

    # Virtual fields
    config.columns << :club_name

    config.columns << :dictionary_name
    config.columns[:dictionary_name].label = 'Name'
    config.columns[:dictionary_name].sort = true
    config.columns[:dictionary_name].sort_by :sql => "LOWER(last_name||first_name||middle_name||team_name)"
    config.columns[:dictionary_name].search_sql = "(first_name||middle_name||last_name||team_name)"

    config.columns[:club].includes = [ :club ]
    config.columns[:club].sort_by :sql => 'LOWER(clubs.name)'
    config.columns[:club].search_sql = 'clubs.name'

    config.columns << :postal_address
    config.columns[:postal_address].label = 'Name and Address'

    config.list.sorting = { :dictionary_name => :asc }

    # UI overrides
    config.columns[:address1].options = { :size => 76, :maxlength => 80 }
    config.columns[:address2].options = { :size => 76, :maxlength => 80 }
    config.columns[:address3].options = { :size => 76, :maxlength => 80 }
    config.columns[:address4].options = { :size => 76, :maxlength => 80 }
    config.columns[:city].options = { :size => 25, :maxlength => 80 }
    config.columns[:club_name].options = { :size => 30, :maxlength => 60 }
    config.columns[:email].options = { :size => 40, :maxlength => 100 }
    config.columns[:first_name].options = { :size => 25, :maxlength => 80 }
    config.columns[:last_name].options = { :size => 25, :maxlength => 80 }
    config.columns[:middle_name].options = { :size => 15, :maxlength => 80 }
    config.columns[:phone].options = { :size => 20, :maxlength => 40 }
    config.columns[:postcode].options = { :size => 10, :maxlength => 20 }
    config.columns[:team_members].options = { :size => 76, :maxlength => 255 }
    config.columns[:team_name].options = { :size => 76, :maxlength => 80 }

    config.columns[:club].clear_link
  end

  def help
    render :partial => 'help'
  end

  protected

    def do_new
      super
      if session[:last_region_id]
        @record.region_id = session[:last_region_id]
      elsif session[:geocode_ip]
        region = get_region_from(session[:geocode_ip])
        @record.region_id = region[:id] if region
      end
    end

    def do_destroy
      super
      @entry_count = current_user.entries.count
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
      @is_admin_view = session[:entrants_admin_view] = active_scaffold_constraints[:user_id].nil?
      if @is_admin_view
        super
      else
        logged_in? && (params[:id].nil? ||
                       authorized_for?(Entrant.find_by_id(params[:id])))
      end
    end

    def update_config
      Controller.admin_view = @is_admin_view
      if @is_admin_view
        active_scaffold_config.list.per_page = 100
        active_scaffold_config.theme = :blue
      else
        active_scaffold_config.list.per_page = 20
        active_scaffold_config.theme = :default
      end

      # WARNING: We're abusing action_after_create to open a new entries form.
      # The way we're (ab)using it only works for XHR requests. It should be a
      # controller action, but that doesn't fit with the current design of the form.
      active_scaffold_config.create.action_after_create = request.xhr? ? 'entries-nested' : nil
    end

    def search_authorized?
      @is_admin_view
    end

    def help_authorized?
      !@is_admin_view
    end

end
