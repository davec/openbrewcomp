# -*- coding: utf-8 -*-

module Admin::FlightsHelper

  PLACES     = [ ['-', 0], ['1', 1], ['2', 2], ['3', 3], ['HM', 4] ].freeze
  #BOS_PLACES = [ ['-', 0], ['1', 1], ['2', 2], ['3', 3] ].freeze
  BOS_PLACES = PLACES

  TIME_FORMAT_VERBOSE = '%a, %b %e, %Y %l:%M %p'.freeze
  TIME_FORMAT_SHORT = '%Y-%m-%d %H:%M'.freeze

  def assigned_column(record)
    record.assigned? ? 'Yes' : 'No'
  end

  def completed_column(record)
    record.completed? ? 'Yes' : 'No'
  end

  def round_column(record)
    record.round.name.gsub(/round/i, '')
  end

  def status_column(record)
    status = record.status_label
    return status unless %w(row table push).include? controller.action_name
    %Q{<span class="#{status.downcase}">#{status.titleize}</span>}
  end

  def assigned_time_column(record)
    return '' if record.assigned_time.nil?
    record.assigned_time.strftime(Controller.nested_view? ? TIME_FORMAT_SHORT : TIME_FORMAT_VERBOSE)
  end

  def assigned_time_show_column(record)
    record.assigned_time.nil? ? '' : record.assigned_time.strftime(TIME_FORMAT_VERBOSE)
  end

  def completed_time_column(record)
    return '' if record.completed_time.nil?
    record.completed_time.strftime(Controller.nested_view? ? TIME_FORMAT_SHORT : TIME_FORMAT_VERBOSE)
  end

  def completed_time_show_column(record)
    record.completed_time.nil? ? '' : record.completed_time.strftime(TIME_FORMAT_VERBOSE)
  end

  def judgings_show_column(record)
    judges_table(record)
  end

  def entries_show_column(record)
    entries_table(record, controller.action_name)
  end

  def status_form_column(record, input_name)
    returning String.new do |str|
      FlightStatus.key_value_pairs.each do |s|
        options = form_element_input_options(input_name, Flight)
        options[:onclick] = "setJudgingSession(#{@default_judging_session.id}, #{options[:id].sub(/_status_([[:xdigit:]]+).*/,'_judging_session_\1')})" unless !record.judging_session.nil? || @default_judging_session.nil? || FlightStatus.new(s[0]).unassigned?
        options[:id] += "_#{pretty_tag_value(s[0])}"
        str << radio_button(:record, :status, s[0], options)
        str << %Q{<span class="radioLabel">#{s[1]}</span>}
      end
    end
  end

  def award_form_column(record, input_name)
    return %Q{<span class="readonly">#{h Award.find(record.award_id).name}</span>} unless record.new_record?

    options = form_element_input_options(input_name, Flight)
    options[:name] += "[id]"
    select :record, :award_id,
           Award.all(:order => "category_id, position").map { |a| [ a.name, a.id ] },
           { :prompt => "- Select an award category -" },
           options
  end

  def round_form_column(record, input_name)
    return %Q{<span class="readonly">#{h Round.find(record.round_id).name}</span>} unless record.new_record?

    options = form_element_input_options(input_name, Flight)
    options[:name] += "[id]"
    select :record, :round_id,
           Round.all(:order => "id").map { |r| [ r.name, r.id ] },
           { :prompt => "- Select a round -" },
           options
  end

  def judging_session_form_column(record, input_name)
    options = form_element_input_options(input_name, Flight)
    options[:name] += "[id]"
    select :record, :judging_session_id,
           JudgingSession.current_and_past.map { |s| [ s.description, s.id ] },
           { :prompt => "- Select a judging session -" },
           options
  end

  def entries_form_column(record, input_name)
    # This is only used in the edit action
    if [ 'edit', 'update' ].include?(controller.action_name)
      entries_table(record, controller.action_name)
    else
      raise "Action '#{controller.action_name}' not recognized"
    end
  end

  def element_handle_id(entry)
    "entry_#{entry.id}"
  end

  def award_container_id(award)
    "award#{award.id}"
  end

  def flights_container_id(award)
    "#{award_container_id(award)}-assignments"
  end

  def flight_container_width_in_ems
    8.5
  end

  def flight_processing_div_id(award)
    "#{award_container_id(award)}-processing"
  end

  def print_flight_sheets_div_id
    'print-all-flight-sheets'
  end

  private

    def judges_table(record)
      panel = record.judgings.partition{|r| r.role == Judging::ROLE_JUDGE}
      judges = panel[0]
      stewards = panel[1]

      (judges.sort{|x,y| x.judge.dictionary_name <=> y.judge.dictionary_name}.map{|j| link_to(h(j.judge.name), admin_judge_path(j.judge), :popup => true)} +
       stewards.sort{|x,y| x.judge.dictionary_name <=> y.judge.dictionary_name}.map{|j| %Q{#{link_to(h(j.judge.name), admin_judge_path(j.judge), :popup => true)} <span style="font-weight: normal">(Steward)</span>} }).join('<br />')
    end

    def entries_table(record, action)
      is_mcab_comp = competition_data.mcab?
      is_first_time_category = record.award.style_ids.length == 1 && record.award.styles.first.first_time?
      sort_keys = is_first_time_category \
        ? lambda{|e| [e.base_style.bjcp_category,e.base_style.bjcp_subcategory,e.bottle_code]} \
        : lambda{|e| [e.style.bjcp_category,e.style.bjcp_subcategory,e.bottle_code]}
      include_scores = record.round != Round.bos && action != 'show'
      table_width = record.round == Round.bos ? (is_mcab_comp ? 20 : 15) : (include_scores ? 32 : 15)
      rv = %Q{<table class="flight-entries" style="width:#{table_width}em"><tr><th colspan="2" #{'rowspan="2"' if include_scores}>Entry</th><th #{'rowspan="2"' if include_scores}>}
      case record.round
      when Round.first
        rv << 'Advance?'
      when Round.second
        rv << 'Place'
      when Round.bos
        rv << 'MCAB QE?</th><th>' if is_mcab_comp
        rv << 'Place'
      end
      if include_scores
        rv << %Q{</th><th colspan="#{record.max_judges}">Scores</th></tr><tr><th>}
        1.upto(record.max_judges) do |i|
          rv << '</th><th>' unless i == 1
          rv << "Judge #{i}"
          #rv << record.judging_judges[i-1].judge.name
        end
      end
      rv << '</th></tr>'
      record.entries.sort_by{|e| sort_keys.call(e)}.each do |entry|
        unless is_first_time_category
          style_name = entry.style.name
          style_category = entry.style.category
        else
          style_name = entry.base_style.name
          style_category = entry.base_style.category
        end

        rv << %Q{<tr class="#{cycle('odd-record', 'even-record')}"><td class="entry">#{action == 'show' ? link_to(h(entry.bottle_code), admin_entry_path(entry), :popup => true) : h(entry.bottle_code)}}
        unless action == 'show'
          # Force a hidden form field containing the entry ID.
          # This is required to allow the entry to be saved.
          rv << hidden_field("record_#{record.id}_entries_#{entry.id}", :id,
                             { :name => "record[entries][#{entry.id}][id]",
                               :value => entry.id })
        end
        rv << %Q{</td><td class="category"><span title="#{h style_name}">(#{h style_category})</span></td><td>}
        unless action == 'show'
          case record.round
          when Round.first
            rv << check_box("record_#{record.id}_entries_#{entry.id}", :second_round,
                            { :name => "record[entries][#{entry.id}][second_round]",
                              :checked => entry.second_round })
          when Round.second
            rv << select("record_#{record.id}_entries_#{entry.id}", :place, PLACES,
                         { :selected => entry.place || 0 },
                         { :name => "record[entries][#{entry.id}][place]" })
          when Round.bos
            if is_mcab_comp
              rv << check_box("record_#{record.id}_entries_#{entry.id}", :mcab_qe,
                              { :name => "record[entries][#{entry.id}][mcab_qe]" }.merge(entry.style.mcab_style? ? { :checked => entry.mcab_qe } : { :disabled => true }))
              rv << '</td><td>'
            end
            rv << select("record_#{record.id}_entries_#{entry.id}", :bos_place, BOS_PLACES,
                         { :selected => entry.bos_place || 0 },
                         { :name => "record[entries][#{entry.id}][bos_place]" })
          end
          if include_scores
            temp_id = generate_temporary_id + '%04d' % entry.id
            1.upto(record.max_judges) do |i|
              rv << '</td><td>'

              judge = record.judging_judges[i-1].judge rescue nil
              score = entry.scores.detect{|score| score.flight_id == record.id && score.judge_id == judge.id} unless judge.nil?
              score_id = score.nil? ? (temp_id + i.to_s) : score.id
              score_value = score.nil? ? '' : score.score
              rv << text_field("record_#{record.id}_#{score_id}_#{i}", :id,
                               { :name => "record[scores][#{score_id}][score]",
                                 :value => score_value,
                                 :class => 'text-input',
                                 :disabled => judge.nil?,
                                 :size => 3,
                                 :maxlength => 5 })
              rv << hidden_field("record_#{record.id}_#{score_id}_#{i}_entry", :id,
                                 { :name => "record[scores][#{score_id}][entry][id]",
                                   :value => entry.id })
              rv << hidden_field("record_#{record.id}_#{score_id}_#{i}_judge", :id,
                                 { :name => "record[scores][#{score_id}][judge][id]",
                                   :value => judge.nil? ? '' : judge.id })
              rv << hidden_field("record_#{record.id}_#{score_id}_#{i}_flight", :id,
                                 { :name => "record[scores][#{score_id}][flight][id]",
                                   :value => record.id })
            end
          end
        else
          case record.round
          when Round.first
            rv << (entry.second_round? ? check_mark : '&nbsp;')
          when Round.second
            rv << (entry.place.nil? ? '&nbsp;' : PLACES.rassoc(entry.place)[0])
          when Round.bos
            if is_mcab_comp
              rv << (entry.mcab_qe? ? check_mark : '&nbsp;')
              rv << '</td><td>'
            end
            rv << (entry.bos_place.nil? ? '&nbsp;' : BOS_PLACES.rassoc(entry.bos_place)[0])
          end
        end
        rv << '</td></tr>'
      end
      rv << '</table>'
      rv
    end

    def check_mark
      '&#x2714;'  # Heavy Check Mark
      #'&#x2718;'  # Heavy Ballot X
    end

    def rtex_style_notes(entry)
      base_style = entry.base_category
      unless base_style.blank?
        prefix = 'Base Style: ' unless entry.style.first_time?
        base_style = "\\textbf{\\small{#{prefix}#{l(base_style)}}}"
      end
      carbonation = "\\textbf{\\small{Carbonation: #{l(entry.carbonation.description)}}}" if entry.style.require_carbonation?
      strength = "\\textbf{\\small{Strength: #{l(entry.strength.description)}}}" if entry.style.require_strength?
      sweetness = "\\textbf{\\small{Sweetness: #{l(entry.sweetness.description)}}}" if entry.style.require_sweetness?
      [ base_style, carbonation, strength, sweetness, l(entry.style_info.to_s) ].compact.join("\n").strip.gsub("\n", " \\\\newline ")
    end

end
