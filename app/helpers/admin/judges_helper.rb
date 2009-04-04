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
    # method to get the correct output for the checkbox for the index, row, and
    # update_table actions, when updates are allowed.  Otherwise, we show a
    # Yes/No string.
    if [ 'index', 'row', 'update_table' ].include?(controller.action_name) and record.authorized_for?(:action => :update, :column => :checked_in)
      column = ActiveScaffold::DataStructures::Column.new(:checked_in, record.class)
      column.inplace_edit = true
      column.form_ui = :checkbox
      format_inplace_edit_column(record, column)
    else
      record.checked_in? ? 'Yes' : 'No'
    end
  end

  def confirmed_column(record)
    unless record.confirmed.nil?
      record.confirmed? ? 'Yes' : 'No'
    end
  end

  def organizer_column(record)
    'Yes' if record.organizer?
  end

  def comments_column(record)
    controller.action_name == 'show' ? h(record.comments) : h(truncate(record.comments, :length => 20))
  end

  def is_bos_judge_column(record)
    return '-' if record.organizer?
    'Yes' if record.is_bos_judge?
  end

  def staff_points_column(record)
    return '-' if record.organizer?
    "%.1f" % record.staff_points if record.staff_points
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
    record.category_preferences.collect(&:label).join("<br />")
  end

  def time_availabilities_column(record)
    return '-' if record.time_availabilities.empty?
    record.time_availabilities.sort_by{|t| t.start_time}.collect(&:label).join("<br />")
  end

  def judge_rank_option_value(rank, extended=false)
    value = "#{rank.id}"
    if extended
      value << ",#{rank.bjcp? ? 't' : 'f'}"
    end
    value
  end

end
