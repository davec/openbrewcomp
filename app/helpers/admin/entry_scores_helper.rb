# -*- coding: utf-8 -*-

module Admin::EntryScoresHelper

  def avg_score_column(record)
    record.avg_score.is_a?(Numeric) ? ("%.1f" % record.avg_score) : record.avg_score
  end

  def place_column(record)
    record.place.to_i > 3 ? 'HM' : record.place
  end

  def scores_column(record)
    record.scores.nil? ? 'N/A' : record.scores.map(&:score).join(', ')
  end

  def award_container_id(award)
    "award#{award.id}"
  end

  def bottle_code_form_column(record, input_name)
    %Q{<span class="readonly">#{record.bottle_code}</span>}
  end

  def category_form_column(record, input_name)
    %Q{<span class="readonly">#{record.category}</span>}
  end

  def place_form_column(record, input_name)
    %Q{<span class="readonly">#{record.place}</span>}
  end

  def scores_form_column(record, input_name)
    scores_table(record)
  end

  private

  def scores_table(entry)
    temp_id = generate_temporary_id + '%04d' % entry.id
    rv = ''
    flights = entry.scores.group_by{|score| score.flight}.sort_by{|flight| flight[0].round_id}
    flights.each do |record|
      flight = record[0]
      judges = flight.judgings.inject([]){|arr,j| arr << j.judge if j.role == Judging::ROLE_JUDGE}
      scores = record[1].inject({}){|hsh,v|
        hsh[v.judge_id] = v
        hsh
      }
      rv << %Q{<div class="scores-table-title">#{flight.round.name}</div>} if flights.length > 1
      rv << %Q{<table class="entry-scores"><tr><th>Judge</th><th>Score</th></tr>}
      judges.sort_by(&:dictionary_name).each_with_index do |judge,idx|
        rv << '<tr>'
        rv << %Q{<td class="judge">#{h judge.name}</td>}
        rv << '<td class="score">'
        score_id = scores[judge.id] ? scores[judge.id].id : temp_id + idx.to_s
        score_value = scores[judge.id] ? scores[judge.id].score : ''
        rv << text_field("record_#{flight.id}_#{score_id}_#{idx}", :id,
                         { :name => "record[scores][#{score_id}][score]",
                           :value => score_value,
                           :class => 'text-input',
                           :size => 3,
                           :maxlength => 5 })
        rv << hidden_field("record_#{flight.id}_#{score_id}_#{idx}_entry", :id,
                           { :name => "record[scores][#{score_id}][entry][id]",
                             :value => entry.id })
        rv << hidden_field("record_#{flight.id}_#{score_id}_#{idx}_judge", :id,
                           { :name => "record[scores][#{score_id}][judge][id]",
                             :value => judge.id })
        rv << hidden_field("record_#{flight.id}_#{score_id}_#{idx}_flight", :id,
                           { :name => "record[scores][#{score_id}][flight][id]",
                             :value => flight.id })
        rv << "</td>"
        rv << "</tr>"
      end
      rv << "</table>"
    end
    rv
  end

end
