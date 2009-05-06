# -*- coding: utf-8 -*-

class Admin::ReportsController < AdministrationController

  def index
    @has_processed_entries = !Entry.checked_in.empty?
  end

  def report_entries_by_individual
    @individuals = Entrant.find_by_sql(sql_for(:individuals))

    if request.xhr?
      render :partial => 'individuals', :object => @individuals, :layout => false
    else
      render :template => "#{params[:controller]}/individuals"
    end
  end

  def report_entries_by_team
    @teams = Entrant.find_by_sql(sql_for(:teams))

    if request.xhr?
      render :partial => 'teams', :object => @teams, :layout => false
    else
      render :template => "#{params[:controller]}/teams"
    end
  end

  def report_entries_by_club
    @clubs = Club.find_by_sql(sql_for(:clubs))

    if request.xhr?
      render :partial => 'clubs', :object => @clubs, :layout => false
    else
      render :template => "#{params[:controller]}/clubs"
    end
  end

  def report_entries_by_style
    @categories = Category.all(:include => [ :awards, :styles ],
                               :conditions => [ 'categories.is_public = ?', true ],
                               :order => 'categories.position, awards.position, styles.bjcp_category, styles.bjcp_subcategory')
    @style_counts = Style.find_by_sql(sql_for(:style_counts)).inject({}){|hsh,v|
      hsh[v.id] = v.entry_count.to_i
      hsh
    }

    if request.xhr?
      render :partial => 'categories', :object => @categories, :layout => false,
                                       :locals => { :style_counts => @style_counts }
    else
      render :template => "#{params[:controller]}/categories"
    end
  end

  def report_entries_by_region
    @regions = Region.find_by_sql(sql_for(:regions))

    if request.xhr?
      render :partial => 'regions', :object => @regions, :layout => false
    else
      render :template => "#{params[:controller]}/regions"
    end
  end

  def report_excess_entries
    @entrants = Award::MAX_ENTRIES ? Entrant.find_by_sql(sql_for(:excess_entries)) : nil

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

  private

    def sql_for(type, pretty_print = false)
      sql = case type
            when :individuals, :teams
              t = %Q{
  SELECT COUNT(e.id) AS entry_count, b.*
  FROM ((entries AS e INNER JOIN entrants AS b ON (b.id = e.entrant_id))
                      INNER JOIN clubs AS c ON (c.id = b.club_id))
  WHERE b.is_team = ?
        #{params[:type] == 'processed' ? 'AND e.bottle_code IS NOT NULL' : ''}
  GROUP BY #{Entrant.columns.collect{|c| "b.#{c.name}"}.join(', ')}
  ORDER BY entry_count DESC, lower(#{type == :individuals ? 'b.last_name||b.first_name||b.middle_name' : 'b.team_name'})
}
              [ t, type == :teams ]
            when :clubs
              %Q{
  SELECT COUNT(e.id) AS entry_count, c.*
  FROM ((entries AS e INNER JOIN entrants AS b ON (b.id = e.entrant_id))
                      INNER JOIN clubs AS c ON (c.id = b.club_id))
  #{params[:type] == 'processed' ? 'WHERE e.bottle_code IS NOT NULL' : ''}
  GROUP BY #{Club.columns.collect{|c| "c.#{c.name}"}.join(', ')}
  ORDER BY entry_count DESC, lower(c.name)
}
            when :style_counts
              %Q{
  SELECT COUNT(e.id) AS entry_count, s.id
  FROM (entries AS e INNER JOIN styles AS s ON (s.id = e.style_id))
  #{params[:type] == 'processed' ? 'WHERE e.bottle_code IS NOT NULL' : ''}
  GROUP BY s.id
}
            when :regions
              %Q{
  SELECT COUNT(e.id) AS entry_count, c.name AS country_name, r.*
  FROM (((entries AS e INNER JOIN entrants ON (entrants.id = e.entrant_id))
                       INNER JOIN countries AS c ON (c.id = entrants.country_id))
                       INNER JOIN regions AS r ON (r.id = entrants.region_id))
  #{params[:type] == 'processed' ? 'WHERE e.bottle_code IS NOT NULL' : ''}
  GROUP BY c.name, #{Region.columns.collect{|c| "r.#{c.name}"}.join(', ')}
  ORDER BY c.name, r.name
}
            when :excess_entries
              %Q{
  SELECT styles.award_id, awards.name AS award_name, e.*
  FROM (((entrants AS e INNER JOIN entries ON (e.id = entries.entrant_id))
                        INNER JOIN styles ON (entries.style_id = styles.id))
                        INNER JOIN awards ON (styles.award_id = awards.id))
  #{params[:type] == 'processed' ? 'WHERE entries.bottle_code IS NOT NULL' : ''}
  GROUP BY styles.award_id, awards.name, #{Entrant.columns.collect{|c| "e.#{c.name}"}.join(', ')}
  HAVING COUNT(styles.award_id) > #{Award::MAX_ENTRIES}
  ORDER BY e.id, styles.award_id
}
            end

      unless pretty_print
        # Remove unnecessary whitespace
        if sql.is_a?(Array)
          sql.first.squish!
        else
          sql.squish!
        end
      end

      sql
    end

end
