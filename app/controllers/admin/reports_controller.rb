# -*- coding: utf-8 -*-

class Admin::ReportsController < AdministrationController

  def index
    @has_processed_entries = !Entry.checked_in.empty?
  end

  def report_entries_by_individual
    conditions = 'entrants.is_team = ?';
    conditions << ' AND entries.bottle_code IS NOT NULL' if params[:type] == 'processed'
    entrants = Entrant.all(:conditions => [ conditions, false ], :include => [ :entries ])
    # TODO: Perform secondary sort on entrant name in ascending alphabetical order
    @individuals = entrants.reject{|e| e.entries.length == 0}.collect{|e| [ e.name, e.club.name, e.entries.length ]}.sort_by{|a| a[2]}.reverse

    if request.xhr?
      render :partial => 'individuals', :object => @individuals, :layout => false
    else
      render :template => "#{params[:controller]}/individuals"
    end
  end

  def report_entries_by_team
    conditions = 'entrants.is_team = ?';
    conditions << ' AND entries.bottle_code IS NOT NULL' if params[:type] == 'processed'
    entrants = Entrant.all(:conditions => [ conditions, true ], :include => [ :entries ])
    # TODO: Perform secondary sort on entrant name in ascending alphabetical order
    @teams = entrants.reject{|e| e.entries.length == 0}.collect{|e| [ e.name, e.club.name, e.entries.length ]}.sort_by{|a| [ a[2], a[0], a[1] ]}.reverse

    if request.xhr?
      render :partial => 'teams', :object => @teams, :layout => false
    else
      render :template => "#{params[:controller]}/teams"
    end
  end

  def report_entries_by_club
    conditions = 'entries.bottle_code IS NOT NULL' if params[:type] == 'processed'
    clubs = Club.all(:conditions => conditions, :include => [ :entries ])
    # TODO: Perform secondary sort on club name in ascending alphabetical order
    @clubs = clubs.reject{|c| c.entries.length == 0}.collect{|c| [ c.name, c.entries.length ]}.sort_by{|a| a[1]}.reverse

    if request.xhr?
      render :partial => 'clubs', :object => @clubs, :layout => false
    else
      render :template => "#{params[:controller]}/clubs"
    end
  end

  def report_entries_by_style
    # FIXME: The entries table cannot be included here. Something wrong with
    # the model defs? Thus, a lot of additional work in the template.
    @categories = Category.find(:all,
                                :include => [ :awards, :styles ],
                                :conditions => [ 'categories.is_public = ?', true ])

    if request.xhr?
      render :partial => 'categories', :object => @categories, :layout => false
    else
      render :template => "#{params[:controller]}/categories"
    end
  end

  def report_entries_by_region
    sql = 'SELECT COUNT(e.id) AS entry_count, c.name AS country_name, r.* FROM (((entries AS e INNER JOIN entrants ON (entrants.id = e.entrant_id)) INNER JOIN countries AS c ON (c.id = entrants.country_id)) INNER JOIN regions AS r ON (r.id = entrants.region_id))'
    sql << ' WHERE e.bottle_code IS NOT NULL' if params[:type] == 'processed'
    sql << ' GROUP BY c.name, '
    sql << Region.columns.collect{|c| "r.#{c.name}"}.join(', ')
    sql << ' ORDER BY c.name, r.name'
    @regions = Region.find_by_sql(sql)

    if request.xhr?
      render :partial => 'regions', :object => @regions, :layout => false
    else
      render :template => "#{params[:controller]}/regions"
    end
  end

  def report_excess_entries
    sql = 'SELECT styles.award_id, awards.name AS award_name, e.* FROM (((entrants AS e INNER JOIN entries ON (e.id = entries.entrant_id)) INNER JOIN styles ON (entries.style_id = styles.id)) INNER JOIN awards ON (styles.award_id = awards.id))'
    sql << ' WHERE entries.bottle_code IS NOT NULL' if params[:type] == 'processed'
    sql << ' GROUP BY styles.award_id, awards.name, '
    sql << Entrant.columns.collect{|c| "e.#{c.name}"}.join(', ')
    sql << " HAVING COUNT(styles.award_id) > #{Award::MAX_ENTRIES}" if Award::MAX_ENTRIES
    sql << ' ORDER BY e.id, styles.award_id'
    @entrants = Entrant.find_by_sql(sql)

    if request.xhr?
      render :partial => 'excess', :object => @entrants, :layout => false
    else
      render :template => "#{params[:controller]}/excess"
    end
  end

  def report_confirmed_judges
    @judges = Judge.confirmed.order('last_name, first_name, middle_name')
    if request.xhr?
      render :partial => 'judges', :object => @judges, :layout => false
    else
      render :template => "#{params[:controller]}/judges"
    end
  end

end
