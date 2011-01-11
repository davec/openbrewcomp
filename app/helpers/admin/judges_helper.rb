# -*- coding: utf-8 -*-

module Admin::JudgesHelper

  TIME_FORMAT = '%Y-%m-%d<br />%H:%M:%S'.freeze

  def updated_at_column(record)
    tz = competition_data.timezone
    record.updated_at.nil? || record.updated_at == record.created_at ? "-" : tz.utc_to_local(record.updated_at).strftime(TIME_FORMAT)
  end

  def postal_address_column(record)
    h(record.postal_address).strip.squeeze("\n").gsub("\n", "<br />")
  end

  def checked_in_column(record)
    # HACK: This seems to be the only way to vary the inplace editing and
    # plain text depending on the controller action.
    #
    # We create a "dummy" column -- because we don't seem to have access to the
    # real column in the caller -- to pass off to the format_inplace_edit_column
    # method to get the correct output for the checkbox for the index and row
    # actions, when updates are allowed.  Otherwise, we show a Yes/No string.
    if %w(index row).include?(controller.action_name) and record.authorized_for?(:action => :update, :column => :checked_in)
      column = ActiveScaffold::DataStructures::Column.new(:checked_in, record.class)
      column.inplace_edit = true
      column.form_ui = :checkbox
      format_inplace_edit_column(record, column)
    else
      record.checked_in? ? 'Yes' : 'No'
    end
  end

  def confirmed_column(record)
    # The same comments in #checked_in_column (above) apply here
    if %w(index row).include?(controller.action_name) and record.authorized_for?(:action => :update, :column => :confirmed)
      column = ActiveScaffold::DataStructures::Column.new(:confirmed, record.class)
      column.inplace_edit = true
      column.form_ui = :checkbox
      format_inplace_edit_column(record, column)
    else
      record.confirmed? ? 'Yes' : 'No'
    end
  end

  def organizer_column(record)
    'Yes' if record.organizer?
  end

  def comments_column(record)
    h(truncate(record.comments, :length => 100))
  end

  def comments_show_column(record)
    h record.comments
  end

  def is_bos_judge_column(record)
    return '-' if record.organizer?
    'Yes' if record.is_bos_judge?
  end

  def staff_points_column(record)
    return '-' if record.organizer?
    "%.1f" % record.staff_points if record.staff_points > 0
  end

  def judge_points_column(record)
    return '-' if record.organizer?
    "%.1f" % record.judge_points if record.judge_points > 0
  end

  def steward_points_column(record)
    return '-' if record.organizer?
    "%.1f" % record.steward_points if record.steward_points > 0
  end

  def judge_number_column(record)
    record.judge_number unless record.judge_number.nil?
  end

  def category_preferences_column(record)
    return '-' if record.category_preferences.empty?
    record.category_preferences.map(&:label).join("<br />")
  end

  def time_availabilities_column(record)
    return '-' if record.time_availabilities.empty?
    record.time_availabilities.sort_by{|t| t.start_time}.map(&:label).join("<br />")
  end

  def club_form_column(record, input_name)
    options = form_element_input_options(input_name, Judge)
    options[:name] += '[id]'
    options[:onchange] = %Q{toggleOtherClubData('#{params[:eid] || params[:id]}',#{Club.other.id})}
    clubs = Club.named.all(:order => 'LOWER(name)').map{|c| [c.name, c.id]}
    clubs << [ Club.other.name, Club.other.id ]

    select(:record, :club_id, clubs,
           { :prompt => '- Please select a club -' },
           options)
  end

  def confirmed_form_column(record, input_name)
    no_value = false
    yes_value = true
    yes_options = form_element_input_options(input_name, Judge)
    no_options = yes_options.dup
    no_options[:id] += "_#{pretty_tag_value(no_value)}"
    yes_options[:id] += "_#{pretty_tag_value(yes_value)}"
    yes_options[:checked] = true if record.confirmed.nil?

    returning String.new do |str|
      str << radio_button(:record, :confirmed, yes_value, yes_options)
      str << %Q{<span class="radioLabel">Yes, I will judge</span>}
      str << radio_button(:record, :confirmed, no_value, no_options)
      str << %Q{<span class="radioLabel">No, I am unable to judge</span>}
    end
  end

  def judge_rank_form_column(record, input_name)
    options = form_element_input_options(input_name, Judge)
    options[:name] += '[id]'
    options[:onchange] = %Q{showJudgeRankParams('#{params[:eid] || params[:id]}')}
    judge_ranks = JudgeRank.all(:order => 'position').map{|r|
      # HACK: Don't offer the N/A rank on new records.
      # (It's a special rank which is only used for importing BJCP judge
      # lists that sometimes include such a value for the judge rank.)
      [ r.description, judge_rank_option_value(r, true) ] unless record.new_record? && r.description == 'N/A'
    }.compact

    select(:record, :judge_rank_id, judge_ranks,
           { :prompt => '- Please select a rank -' },
           options)
  end

  def organizer_form_column(record, input_name)
    options = form_element_input_options(input_name, Judge)
    options[:onclick] = %Q{toggleStaffPoints('#{params[:eid] || params[:id]}')} if @is_admin_view

    check_box(:record, :organizer, options)
  end

  def region_form_column(record, input_name)
    options = form_element_input_options(input_name, Judge)
    options[:name] += '[id]'
    countries = Country.selectable.all(:order => 'name')

    returning String.new do |str|
      str << %Q{<select id="#{options[:id]}" name="#{options[:name]}">}
      str << %Q{<option value="">Please select</option>}  if record.region_id.nil?
      str << option_groups_from_collection_for_select(countries,
                                                      'regions_by_name', 'name',
                                                      'id', 'name',
                                                      record.region_id)
      str << '</select>'
    end
  end

  def staff_points_form_column(record, input_name)
    options = form_element_input_options(input_name, Judge)
    options[:disabled] = @available_staff_points.to_f == 0
    options[:size] = options[:maxsize] = 3
    options[:class] = "#{options[:class]} text-input".strip

    returning String.new do |str|
      str << text_field(:record, :staff_points, options)
      str << %Q{<span class="description">(#{@available_staff_points} available)</span>}
    end
  end

  private

    def judge_rank_option_value(rank, extended=false)
      returning String.new do |value|
        value << "#{rank.id}"
        value << ",#{rank.bjcp? ? 't' : 'f'}" if extended
      end
    end

end
