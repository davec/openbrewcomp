# -*- coding: utf-8 -*-

module Admin::UsersHelper

  TIME_FORMAT = '%Y-%m-%d %H:%M:%S %Z'

  # Define the protected username.
  # (For now we only support a single protected username.)
  def protected_username
    APP_CONFIG[:admin_name]
  end

  def enabled_column(record)
    record.enabled? ? "Yes" : "No"
  end

  def is_admin_column(record)
    record.is_admin? ? "Yes" : "No"
  end

  def require_password_change_column(record)
    record.require_password_change? ? "Yes" : "No"
  end

  def created_at_column(record)
    record.created_at.nil? ? "-" : record.created_at.strftime(TIME_FORMAT)
  end

  def updated_at_column(record)
    record.updated_at.nil? || record.updated_at == record.created_at ? "-" : record.updated_at.strftime(TIME_FORMAT)
  end

  def last_logon_at_column(record)
    record.last_logon_at.nil? ? "-" : record.last_logon_at.strftime(TIME_FORMAT)
  end

end
