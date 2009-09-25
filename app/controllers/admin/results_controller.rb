# -*- coding: utf-8 -*-

class Admin::ResultsController < AdministrationController

  # FIXME: Push as much processing as possible to the models.
  # This controller needs to go on a diet.

  # Generate award reports.  For the awards ceremony, the medal winners are
  # listed in descending order to make it easier for the announcer to read
  # them, but the web page lists the medal winners in ascending order.
  # The individual and club point counts are listed in descending order
  # in both cases.
  #
  # When calculating the points for the individual and club point totals,
  # 3 points are awarded for a first place, 2 points for second, and 1 point
  # for third.  This works out as (4 - place) which makes the summed point
  # totals equal (4*medals - sum(places)).

  def live
    # TODO: Is HTML sufficient, or do we also need to produce PDF?

    # Generate category award winners (place, MCAB QE, style, entry_name, entrant, club)
    @medals = Entrant.find_by_sql([sql_for(:medals) % 'DESC', true]).inject({}) {|hash,record|
      hash[record.sort_position.to_i] = [] if hash[record.sort_position.to_i].nil?
      record.mcab_qe = (!record.mcab_qe.nil? && ['1','t'].include?(record.mcab_qe)) if record.mcab_qe.kind_of?(String)
      hash[record.sort_position.to_i] += [ record ]
      hash
    }.sort.collect{|r| r[1]}

    # Generate BOS winners (style, entry name, entrant, club)
    if Award.bos_awards.length == 1
      @bos = Entrant.find_by_sql([sql_for(:bos) % [ 'IN', 'DESC' ], Category::CATEGORY_RANGE.to_a])
    else
      @beer_bos = Entrant.find_by_sql([sql_for(:bos) % [ 'NOT IN', 'DESC' ], Category::MEAD_CIDER_RANGE.to_a])
      @mead_bos = Entrant.find_by_sql([sql_for(:bos) % [ 'IN', 'DESC' ], Category::MEAD_CIDER_RANGE.to_a])
    end

    # Generate Individual point totals (place, name, club, points)
    @individuals = Entrant.find_by_sql(sql_for(:individuals))

    # Generate Club point totals (place, club, points)
    @clubs = Club.find_by_sql(sql_for(:clubs))
  end

  def web
    # Send the generated page to the client.

    # Generate category award winners (place, MCAB QE, style, entry_name, entrant, club)
    @medals = Entrant.find_by_sql([sql_for(:medals) % 'ASC', true]).inject({}) {|hash,record|
      hash[record.sort_position.to_i] = [] if hash[record.sort_position.to_i].nil?
      record.mcab_qe = (!record.mcab_qe.nil? && ['1','t'].include?(record.mcab_qe)) if record.mcab_qe.kind_of?(String)
      hash[record.sort_position.to_i] += [ record ]
      hash
    }.sort.collect{|r| r[1]}

    # Generate BOS winners (style, entry name, entrant, club)
    if Award.bos_awards.length == 1
      @bos = Entrant.find_by_sql([sql_for(:bos) % [ 'IN', 'ASC' ], Category::CATEGORY_RANGE.to_a])
    else
      @beer_bos = Entrant.find_by_sql([sql_for(:bos) % [ 'NOT IN', 'ASC' ], Category::MEAD_CIDER_RANGE.to_a])
      @mead_bos = Entrant.find_by_sql([sql_for(:bos) % [ 'IN', 'ASC' ], Category::MEAD_CIDER_RANGE.to_a])
    end

    # Generate Individual point totals (place, name, club, points)
    sql = sql_for(:individuals).dup
    ActiveRecord::Base.connection.add_limit!(sql[0], { :limit => 5 })
    @individuals = Entrant.find_by_sql(sql)

    # Generate Club point totals (place, club, points)
    sql = sql_for(:clubs).dup
    ActiveRecord::Base.connection.add_limit!(sql[0], { :limit => 5 })
    @clubs = Club.find_by_sql(sql)

    send_data(render_to_string(:layout => false), :filename => 'results.html.erb', :type => 'text/plain') if params[:mode] == 'download'
  end

  # Generate cover sheets for each entrant, with a listing of each entry,
  # to accompany all of the entrant's score sheets.
  def entrant_covers
    @entrants = Entrant.all(:include => [ :entries ],
                            :conditions => 'entries.bottle_code IS NOT NULL',
                            :order => 'entrants.club_id, lower(entrants.last_name||entrants.first_name||entrants.middle_name||entrants.team_name)')
    render_pdf 'cover_sheets.pdf', :preprocess => true
  end

  # Generate cover sheets for each entry. This is an alternative to the
  # standard AHA/BJCP entry cover sheets for competitions that do not
  # wish to use them and instead generate the automatically from the
  # competition data in the database.
  def entry_covers
    @entries = Entry.find_by_sql(sql_for(:scores))
    render_pdf 'entry_cover_sheets.pdf', :preprocess => true
  end

  def scores
    @scores = Entry.find_by_sql(sql_for(:scores)).inject({}) {|hash,record|
      hash[record.sort_position.to_i] = [] if hash[record.sort_position.to_i].nil?
      hash[record.sort_position.to_i] += [ record ]
      hash
    }.sort.collect{|r| r[1]}
  end

  # Generate a competition report for MCAB
  def mcab
    @mcab_qes = Entrant.find_by_sql(sql_for(:mcab))
    respond_to do |format|
      format.html
      format.csv {
        csv_data = FasterCSV.generate do |data|
          data << [ 'qualifying style', 'brewer name(s)', 'club affiliation', 'street address', 'city', 'state', 'zip', 'phone', 'email' ]
          @mcab_qes.each do |record|
            data << [ record.qualifying_style, record.expanded_name, record.club.name, record.address, record.city, record.region.region_code, record.postcode, record.phone, record.email ]
          end
        end
        send_data(Iconv.iconv("CP1252//TRANSLIT", "UTF-8", csv_data), :filename => "mcab_report.csv")
      }
    end
  end

  # Generate a competition report for BJCP
  def bjcp
    judging_sessions = JudgingSession.find(:all).reject{|sess| sess.flights.empty?}
    days = judging_sessions.group_by(&:date).length
    session_count = judging_sessions.length
    bos_flights = Flight.bos_flights
    flight_count = bos_flights.inject(0){|count,flight| count + flight.entries.length}
    entry_count = Entry.checked_in.count
    organizer = Judge.find(:first, :conditions => [ 'organizer = ?', true ])
    errors = []
    errors << 'A competition name must be provided' if competition_data.name.blank?
    errors << 'A competition ID must be provided' if competition_data.competition_number.blank?
    errors << 'A competition date must be provided' if competition_data.competition_date.blank?
    errors << 'The competition has no entries' unless entry_count > 0
    errors << 'The competition has no judging sessions' unless session_count > 0
    errors << 'No competition organizer has been defined' if organizer.nil?
    unless errors.empty?
      flash[:error] = errors.join('<br />')
    end
    if request.post?
      @comments = params[:report][:comments]
    else
      # Pre-fill the comments section
      @comments = "Competition data entered by #{current_user.display_name} (_BJCP_ID_) on #{Date.today.to_s(:long)}\nSubmitter Email: #{current_user.email}\n"
      bos_flights.each do |f|
        @comments << "#{f.name}: #{f.entries.length} entries\n"
      end
    end
    @competition_data = {
      :id => competition_data.competition_number,
      :name => competition_data.name,
      :date => competition_data.competition_date,
      :entries => entry_count,
      :days => days,
      :sessions => session_count,
      :flights => flight_count,
      :organizer => organizer.nil? ? '-' : organizer.name
    }
    @bjcp_judges = Judge.bjcp_judges.reject{|j| j.points == 0}
    @non_bjcp_judges = Judge.non_bjcp_judges.reject{|j| j.points == 0}
    respond_to do |format|
      format.html
      #format.xml { render(:layout => false) }  # For debugging in the browser, not for production
      format.xml { send_data(render_to_string(:layout => false), :filename => "bjcp_competition_report_#{competition_data.competition_number}.xml") }
    end
  end

  def send_award
    if request.post?
      entry = Entry.find(params[:id])
      entry.update_attribute(:send_award, params[:status])
      render :nothing => true
    end
  end

  def send_bos_award
    if request.post?
      entry = Entry.find(params[:id])
      entry.update_attribute(:send_bos_award, params[:status])
      render :nothing => true
    end
  end

  private

    def sql_for(type, pretty_print=false)
      sql = case type
            when :medals
              %q{
  SELECT a.name AS award_name, c.position * 10 + a.position AS sort_position, tmp.*
  FROM categories AS c LEFT OUTER JOIN awards AS a ON (c.id = a.category_id)
                       LEFT OUTER JOIN (SELECT a.id AS award_id, e.place AS place, e.mcab_qe AS mcab_qe, s.name AS style_name, e.name AS entry_name, e.id AS entry_id, e.send_award AS send_award, e.style_id AS style_id, e.base_style_id AS base_style_id, b.*
                                        FROM entries AS e, entrants AS b, styles AS s, awards AS a, categories AS c
                                        WHERE e.place IS NOT NULL AND b.id = e.entrant_id AND s.id = e.style_id AND a.id = s.award_id AND c.id = a.category_id) AS tmp ON (a.id = tmp.award_id)
  WHERE c.is_public = ?
  ORDER BY sort_position, a.position, place %s
}

            when :bos
              %q{
  SELECT e.bos_place AS place, s.name AS style_name, e.name AS entry_name, e.id AS entry_id, e.send_bos_award AS send_bos_award, b.*
  FROM entries AS e, entrants AS b, styles AS s
  WHERE e.bos_place IS NOT NULL AND s.bjcp_category %s (?) AND b.id = e.entrant_id AND s.id = e.style_id
  ORDER BY e.bos_place %s
}

            when :mcab
              [ %q{
  SELECT s.bjcp_category AS qualifying_style, c.name AS qualifying_style_name, b.*
  FROM entries AS e, entrants AS b, styles AS s, awards AS a, categories AS c
  WHERE e.mcab_qe = ? AND b.id = e.entrant_id AND s.id = e.style_id AND a.id = s.award_id AND c.id = a.category_id
  ORDER BY s.bjcp_category
}, true ]

            when :scores
              # NOTE: This computes the average score for each entry.
              # FIXME: Alter SQL when support for assigned scores is added.
              %q{
  SELECT a.name AS award_name, s.name AS style_name, e.*, c.position * 10 + a.position AS sort_position, (SELECT AVG(score) FROM scores WHERE scores.entry_id = e.id GROUP BY entry_id) AS score
  FROM entries AS e, styles AS s, awards AS a, categories AS c
  WHERE e.bottle_code IS NOT NULL AND s.id = e.style_id AND a.id = s.award_id AND c.id = a.category_id
  ORDER BY c.position, a.position, COALESCE(e.place, 99), score DESC, e.bottle_code
}

            # NOTE: The point calculations for both individuals and clubs is based on
            # 3 points for first, 2 points for second, and 1 point for third.  This
            # works out to simple arithmetic: 4 * medals - sum(places), e.g.,
            # 2 firsts, 2 seconds, and a third give 5 medals, the sum of the places
            # is 2*1 + 2*2 + 1*3 = 9, so the point total is 4*5 - 9 = 11 which is the
            # same as 2*3 + 2*2 + 1*1.  If some other point basis is used, e.g.,
            # 5 points for first, 3 points for second, and 1 point for third, then
            # these SQL statements must change.

            when :individuals
              [ %Q{
  SELECT 4 * count(e.place) - sum(e.place) AS points, b.*
  FROM entries AS e, entrants AS b, styles AS s
  WHERE b.is_team = ? AND e.place < 4 AND s.point_qualifier = ? AND b.id = e.entrant_id AND s.id = e.style_id
  GROUP BY b.id, #{Entrant.columns.collect(){|c| "b.#{c.name}" unless c.name == 'id'}.compact.join(', ')}
  ORDER BY points DESC, COALESCE(last_name || first_name || middle_name, team_name) ASC
}, false, true ]

            when :clubs
              [ %Q{
  SELECT 4 * count(e.place) - sum(e.place) AS points, c.*
  FROM entries AS e, entrants AS b, clubs AS c, styles AS s
  WHERE e.place IS NOT NULL AND s.point_qualifier = ? AND c.id <> ? AND b.id = e.entrant_id AND c.id = b.club_id AND s.id = e.style_id
  GROUP BY c.id, #{Club.columns.collect(){|c| "c.#{c.name}" unless c.name == 'id'}.compact.join(', ')}
  ORDER BY points DESC, c.name ASC
}, true, Club.independent.id ]
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
