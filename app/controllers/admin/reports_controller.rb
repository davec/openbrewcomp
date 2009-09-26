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
      processed_condition = case params[:type]
                            when "processed"
                              "entries.bottle_code IS NOT NULL"
                            when "unprocessed"
                              "entries.bottle_code IS NULL"
                            else
                              nil
                            end
      sql = case type
            when :individuals, :teams
              name_column = type == :individuals \
                            ? "entrants.last_name||entrants.first_name||entrants.middle_name" \
                            : "entrants.team_name"
              t = %Q{
  SELECT COUNT(entries.id) AS entry_count, entrants.*
  FROM entries, entrants, clubs
  WHERE entrants.is_team = ? AND entrants.id = entries.entrant_id AND clubs.id = entrants.club_id
        #{"AND #{processed_condition}" unless processed_condition.nil?}
  GROUP BY #{Entrant.columns.collect{|c| "entrants.#{c.name}"}.join(", ")}
  ORDER BY entry_count DESC, lower(#{name_column})
}
              [ t, type == :teams ]
            when :clubs
              %Q{
  SELECT COUNT(entries.id) AS entry_count, clubs.*
  FROM entries, entrants, clubs
  WHERE entrants.id = entries.entrant_id AND clubs.id = entrants.club_id
        #{"AND #{processed_condition}" unless processed_condition.nil?}
  GROUP BY #{Club.columns.collect{|c| "clubs.#{c.name}"}.join(", ")}
  ORDER BY entry_count DESC, lower(clubs.name)
}
            when :style_counts
              %Q{
  SELECT COUNT(entries.id) AS entry_count, styles.id
  FROM entries, styles
  WHERE styles.id = entries.style_id
        #{"AND #{processed_condition}" unless processed_condition.nil?}
  GROUP BY styles.id
}
            when :regions
              %Q{
  SELECT COUNT(entries.id) AS entry_count, countries.name AS country_name, regions.*
  FROM entries, entrants, countries, regions
  WHERE entrants.id = entries.entrant_id AND countries.id = entrants.country_id AND regions.id = entrants.region_id
        #{"AND #{processed_condition}" unless processed_condition.nil?}
  GROUP BY countries.name, #{Region.columns.collect{|c| "regions.#{c.name}"}.join(", ")}
  ORDER BY countries.name, regions.name
}
            when :excess_entries
              %Q{
  SELECT styles.award_id, awards.name AS award_name, entrants.*
  FROM entries, entrants, styles, awards
  WHERE entrants.id = entries.entrant_id AND styles.id = entries.style_id AND awards.id = styles.award_id
        #{"AND #{processed_condition}" unless processed_condition.nil?}
  GROUP BY styles.award_id, awards.name, #{Entrant.columns.collect{|c| "entrants.#{c.name}"}.join(", ")}
  HAVING COUNT(styles.award_id) > #{Award::MAX_ENTRIES}
  ORDER BY entrants.id, styles.award_id
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
