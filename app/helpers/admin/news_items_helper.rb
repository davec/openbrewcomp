# -*- coding: utf-8 -*-

module Admin::NewsItemsHelper

  TIME_FORMAT = '%Y-%m-%d %H:%M:%S %Z'

  def author_column(record)
    h(record.author.login)
  end

  def description_raw_column(record)
    # Only show the, possibly truncated, first paragraph of text
    description = record.description_raw.split("\n")
    str = truncate(description.first, :length => 80)
    str += ' ...' if description.length > 1 && str[-3,3] != '...'
    h(str)
  end

  def description_raw_show_column(record)
    %Q(<div class="formatted-preview">#{simple_format(h(record.description_raw))}</div>)
  end

  def description_encoded_show_column(record)
    %Q(<div class="formatted-preview">#{record.description_encoded}</div>)
  end

  def created_at_column(record)
    record.created_at.nil? ? '-' : record.created_at.strftime(TIME_FORMAT)
  end

  def updated_at_column(record)
    record.updated_at.nil? || record.updated_at == record.created_at ? '-' : record.updated_at.strftime(TIME_FORMAT)
  end

  def last_edit_column(record)
    record.last_edit.strftime(TIME_FORMAT)
  end

end
