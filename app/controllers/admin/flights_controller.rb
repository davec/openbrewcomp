# -*- coding: utf-8 -*-

class Admin::FlightsController < AdministrationController

  protect_from_forgery :only => [ :create, :update, :destroy ]

  before_filter :update_config
  before_filter :get_default_judging_session, :only => [ :edit ]

  ALL_LIST_COLUMNS = [ :id, :name, :round, :award, :entry_count, :assigned_time, :status ]
  FULL_LIST_COLUMNS = [ :id, :name, :round, :award, :entry_count, :status ]
  PARTIAL_LIST_COLUMNS = [ :name, :round, :award, :assigned_time, :completed_time, :entry_count, :status ]

  active_scaffold :flights do |config|
    config.list.columns = ALL_LIST_COLUMNS

    config.search.columns = [ :name, :round, :award ]

    config.create.label = 'Create Flight'
    config.create.link.label = 'New Flight'
    config.create.columns = [ :name, :round, :award ]

    config.update.columns = [ :name, :round, :award, :status, :judging_session, :judgings, :entries, :scores ]

    config.show.label = 'Show Flight'
    config.show.columns = [ :name, :round, :award, :status, :assigned_time, :completed_time, :judging_session, :judgings, :entries ]

    # Label overrides
    config.columns[:id].label = 'ID'
    config.columns[:judgings].label = 'Judge Panel'

    # Required fields
    [ :name, :round, :award, :judging_session, :entries ].each do |f|
      config.columns[f].required = true
    end

    # UI overrides
    config.columns[:name].options = { :size => 40, :maxlength => 60 }

    # Virtual columns
    config.columns << :entry_count
    config.columns[:entry_count].label = 'Entries'
    config.columns << :status
    config.columns[:status].required = true
    config.columns[:status].sort_by :method => 'flight_status'
    config.columns << :assigned_time
    config.columns[:assigned_time].label = 'Time Assigned'
    config.columns << :completed_time
    config.columns[:completed_time].label = 'Time Completed'

    config.columns[:round].includes = [ :round, :award ]
    config.columns[:round].sort_by :sql => 'rounds.position'
    config.columns[:round].search_sql = 'rounds.name'

    config.columns[:award].includes = [ :award ]
    config.columns[:award].sort_by :sql => '(10.0*awards.category_id+awards.position)'
    config.columns[:award].search_sql = 'awards.name'

    config.columns[:name].sort_by :sql => 'flights.name'

    # Additional actions

    # Push a single first-round flight to the second round
    config.action_links.add 'push',
                            :label => 'Push',
                            :method => :post,
                            :type => :record,
                            :action => 'push',
                            :crud_type => 'push',
                            :inline => true,
                            :position => false

    # Print flight and pull sheets for the flight
    config.action_links.add 'print',
                            :label => 'Print',
                            :type => :record,
                            :action => 'print',
                            :crud_type => 'print',
                            :popup => true

    # Add a "Show Ineligible Judges" link
    config.action_links.add 'entrants',
                            :label => 'Show Ineligible Judges',
                            :type => :table,
                            :action => 'ineligible_judges',
                            :inline => true,
                            :position => :top,
                            :popup => false
  end

  attr_reader :default_judging_session

  def index
    # Override default AS index
  end

  def assign
    @awards = get_awards
    if request.post?
      errors = []
      raw_min_entries = params[:flight][:min]
      raw_max_entries = params[:flight][:max]
      if raw_min_entries.blank?
        errors << 'The minimum number of entries must not be blank'
      elsif !is_integer?(raw_min_entries)
        errors << 'The mininum number of entries is not an integer number'
      elsif raw_min_entries.to_i <= 0
        errors << 'The minumum number of entries must be greater than zero'
      else
        min_entries = raw_min_entries.to_i
      end
      if raw_max_entries.blank?
        errors << 'The maximum number of entries must not be blank'
      elsif !is_integer?(raw_max_entries)
        errors << 'The maximum number of entries is not an integer number'
      elsif raw_max_entries.to_i <= 0
        errors << 'The maximum number of entries must be greater than zero'
      elsif defined?(min_entries) && raw_max_entries.to_i <= min_entries
        errors << 'The maximum number of entries must be greater than the minimum number of entries'
      else
        max_entries = raw_max_entries.to_i
      end
      if errors.empty?
        # Generate first-round flights and assign entries
        @awards.each do |award|
          award.create_flights_and_assign_entries(min_entries, max_entries)
        end
      elsif errors.length == 1
        flash[:errors] = errors[0]
      else
        flash[:errors] = errors
      end
    end
    @can_auto_assign_flights = Flight.count == 0
  end

  # Add a flight (from the flight assignment page, hence only applies to first round flights
  def add_flight
    @award = Award.find(params[:id])
    new_flight_count = @award.flights.length + 1
    flight = Flight.create!(:name => "#{@award.name} #{new_flight_count}",
                            :award_id => @award.id,
                            :round_id => Round.first.id)
    @flight_count = new_flight_count + 1  # Include the "unassigned" flight
  end

  def delete_flight
    flight = Flight.find(params[:id]) rescue nil
    unless flight.nil? || flight.protected?
      flight.entries.delete_all

      @award = flight.award
      @flight_count = @award.flights.length
      flight.destroy
    end
  end

  def delete_flights
    @award = Award.find(params[:id])
    @award.flights.each do |flight|
      unless flight.protected?
        flight.entries.delete_all
        flight.destroy
      end
    end
    @flight_count = @award.flights.length
  end

  def assign_entry
    entry = Entry.find(params[:entry]) rescue nil
    # If an entry has more than one flight, it's in the second round (or BOS)
    # and can't be reassigned to a different first round flight.  We should
    # never see such a situation
    raise 'Entry assignment not valid for post-first round flights' if entry.flights.length > 1

    unless entry.nil?
      new_flight = Flight.find(params[:id]) rescue nil
      old_flight = Flight.find(entry.flights[0].flight_id) unless entry.flights.empty?
      # Remove the entry from the flight it's currently assigned to, if any
      old_flight.entries.delete(entry) unless old_flight.nil?

      # Add the entry to the flight
      new_flight.entries << entry unless new_flight.nil?

      @award = entry.style.award
    end
  end

  def manage
    @rounds = Round.find(:all, :order => :position)
  end

  def all_flights
    if request.xhr?
      render :partial => "#{params[:action]}", :layout => false
    else
      render #:template => "#{params[:controller]}/all_flights"
    end
  end

  def round_1
    # First Round
    @round = Round.first
    @round_1_awards = get_awards
    if request.xhr?
      render :partial => "#{params[:action]}_awards", :layout => false
    else
      render :template => "#{params[:controller]}/round_flights"
    end
  end

  def round_2
    # Second Round
    @round = Round.second
    @round_2_awards = get_awards

    # Generate second-round flights, if necessary
    @round_2_awards.each(&:create_second_round_flight)

    if request.xhr?
      render :partial => "#{params[:action]}_awards", :layout => false
    else
      render :template => "#{params[:controller]}/round_flights"
    end
  end

  def round_3
    # Best-of-Show
    @round = Round.bos
    @round_3_awards = get_awards(false)

    # Generate BOS flights, if necessary
    @round_3_awards.each(&:create_best_of_show_flight)

    if request.xhr?
      render :partial => "#{params[:action]}_awards", :layout => false
    else
      render :template => "#{params[:controller]}/round_flights"
    end
  end

  def print
    if params.key?(:id)
      flight = Flight.find(params[:id],
                           :include => [ :round, :entries ]) rescue nil
      print_flight_sheets flight
    elsif params.key?(:round)
      flights = Flight.find(:all,
                            :include => [ :round, :entries ],
                            :conditions => [ 'rounds.position = ? AND flights.assigned = ? AND flights.completed = ?', params[:round], false, false ])
      print_flight_sheets flights
    else
      raise ArgumentException, 'Must specify :id or :round'
    end
  end

  def push
    # By defaulting to an unsuccessful action, an invalid request (i.e., an
    # invalid flight ID) will generate an error in the scaffold.  The error
    # that is presented, however, is misleading and not informative.
    #
    # TODO: Consider extending the JS ActiveScaffold object to generate
    # something other than the "standard" 500 error.
    #
    # Alternatively, we could render nothing on error, but doing so does not
    # provide any feedback to the user.

    @successful = false
    @flight = Flight.find(params[:id]) rescue nil
    unless @flight.nil?
      @flight.entries.each{|entry| entry.update_attribute(:second_round, true)}
      @successful = @flight.update_attribute(:completed, true)
      #render and return
    end
    #render(:nothing => true)
  end

  def list_ineligible_judges
    @awards = Award.find_public_awards
    @awards += Award.find_non_public_awards if Round.completed?(Round.second.position)
  end

  def ineligible_judges
    award = Award.find(params[:award_id] || active_scaffold_constraints[:award_id]) rescue nil
    unless award.nil?
      @award_name = award.name
      @ineligible_judges = award.find_all_entrants.sort{|x,y| x.dictionary_name <=> y.dictionary_name}
    else
      @award_name = '(Unknown)'
    end
    if request.xhr? && !active_scaffold_config.action_links[action_name].popup?
      render(:partial => 'ineligible_judges',
             :locals => { :award_name => @award_name,
                          :ineligible_judges => @ineligible_judges }) and return
    end
  end

  def track
    awards_with_first_round_flights = Award.find_awards_with_multiple_first_round_flights
    first_round_flight_count = awards_with_first_round_flights.inject(0){|sum, award|
      sum + award.flights.count(:joins => 'INNER JOIN rounds ON rounds.id = flights.round_id',
                                :conditions => "rounds.position = #{Round.first.position}")
    }
    awards = Award.find_public_awards.reject{|a| a.flights.empty? || a.flights.all?{|f| f.entries.empty?}}
    second_round_flight_count = awards.length

    @total_flights = first_round_flight_count + second_round_flight_count
    @flights_completed = Flight.flights_completed.length
    @flights_in_progress = Flight.flights_in_progress.length
    @flights_remaining = @total_flights - @flights_completed - @flights_in_progress
    @table_caption = "Status of #{Round.first.name} and #{Round.second.name} flights."
  end

  protected

    def update_config
      @is_full_list = active_scaffold_constraints[:round].nil? && !nested?
      Controller.admin_view = true  # So the entry records can be updated
      Controller.nested_view = nested?
      Controller.is_full_list = @is_full_list
      # There's no way to add a column at a specific location in the list, so
      # we exclude all columns and then add the ones we want.
      active_scaffold_config.list.columns.exclude ALL_LIST_COLUMNS
      if @is_full_list
        active_scaffold_config.label = 'Flights'
        active_scaffold_config.columns[:name].label = 'Name'
        active_scaffold_config.columns[:name].sort = true
        active_scaffold_config.columns[:status].sort = true
        active_scaffold_config.theme = :blue
        active_scaffold_config.list.columns.add FULL_LIST_COLUMNS
        active_scaffold_config.list.sorting = [ { :round => :asc }, { :award => :asc }, { :name => :asc } ]
      else
        active_scaffold_config.label = 'Flights'
        active_scaffold_config.list.columns.add PARTIAL_LIST_COLUMNS
        if nested?
          # ACK!  Is there a better way?
          case params[:parent_model].to_s
            #when 'JudgingSession'
            #  active_scaffold_config.list.columns.exclude :round, :award
          when 'Judge'
            active_scaffold_config.list.columns.exclude :assigned_time, :completed_time
          end
          active_scaffold_config.columns[:name].label = 'Name'
          active_scaffold_config.columns[:name].sort = true
          active_scaffold_config.columns[:status].sort = true
          active_scaffold_config.list.sorting = [ { :round => :asc }, { :award => :asc }, { :name => :asc } ]
        else
          active_scaffold_config.label = params[:award] || '(Unknown)'
          active_scaffold_config.list.columns.exclude :completed_time, :round, :award
          active_scaffold_config.columns[:name].label = 'Flight Name'
          # HACK: The only way to get the names sorted is to specify that the
          # name column is sortable. But we don't really want that, so we go
          # ahead and allow AS to configure a sortable name column, then follow
          # up with some JavaScript code in the list view that removes the
          # sortable bits.
          #active_scaffold_config.columns[:name].sort = false
          active_scaffold_config.columns[:status].sort = false
          active_scaffold_config.list.sorting = { :name => :asc }
        end
        active_scaffold_config.theme = :default
      end
      active_scaffold_config.list.per_page = 99999
    end

    def create_authorized?
      @is_full_list
    end

    def delete_authorized?
      @is_full_list
    end

    def search_authorized?
      @is_full_list
    end

    def push_authorized?
      @is_full_list || active_scaffold_constraints[:round] == 1
    end

    #def print_authorized?
    #  !@is_full_list
    #end

    def show_ineligible_judges_authorized?
      !@is_full_list && !nested?
    end

    def do_update
      unless params[:record][:scores].nil?
        params[:record][:scores].delete_if{|key,value| value[:judge][:id].blank? || value[:score].blank?}
        params[:record].delete(:scores) if params[:record][:scores].empty?
      end
      super
    end

  private

    def is_integer?(value)
      value =~ /\A[+-]?\d+\Z/
    end

    def get_awards(public = true)
      categories = Category.find(:all,
                                 :include => [ :awards, :styles ],
                                 :conditions => [ 'categories.is_public = ?', public ],
                                 :order => 'categories.position, awards.position')
      categories.inject([]){|arr,c| arr << c.awards}.flatten
    end

    def print_flight_sheets(*flights)
      @flights = flights.flatten
      unless @flights.empty?
        filename = case @flights.length
                   when 1
                     "flight_#{@flights[0].id}"
                   else
                     @flights[0].round.name.downcase.gsub(/[-:\/\\ ]/, '_')
                   end
        options_for_rtex = { :preprocess => true, :filename => "#{filename}.pdf" }
        options_for_rtex.merge({ :debug => true, :shell_redirect => "> #{File.expand_path(RAILS_ROOT)}/tmp/flight_sheets.rtex.log 2>&1" }) if ENV['RAILS_ENV'] == 'development'
        render options_for_rtex.merge(:layout => false)
      else
        flash[:error] = 'No flights found'
        redirect_to(:back)
      end
    end

    def get_default_judging_session
      @default_judging_session = JudgingSession.find(:first, :conditions => [ '? BETWEEN start_time AND end_time ', Time.now.utc ])
    end

end
