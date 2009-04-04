# -*- coding: utf-8 -*-

module Admin::ContactsHelper

  TIME_FORMAT = '%Y-%m-%d %H:%M:%S %Z'

  def created_at_column(record)
    record.created_at.nil? ? "-" : record.created_at.strftime(TIME_FORMAT)
  end

  def updated_at_column(record)
    record.updated_at.nil? || record.updated_at == record.created_at ? "-" : record.updated_at.strftime(TIME_FORMAT)
  end

end
