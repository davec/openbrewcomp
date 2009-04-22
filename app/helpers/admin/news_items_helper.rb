# -*- coding: utf-8 -*-

module Admin::NewsItemsHelper

  TIME_FORMAT = '%Y-%m-%d %H:%M:%S %Z'

  def author_column(record)
    h(record.author.login)
  end

  def description_raw_column(record)
    h(truncate(record.description_raw, :length => 100))
  end

  def description_encoded_column(record)
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
