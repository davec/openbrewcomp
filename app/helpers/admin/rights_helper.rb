# -*- coding: utf-8 -*-

module Admin::RightsHelper

  def name_column(record)
    h record.name.titleize
  end

  def roles_column(record)
    record.roles.nil? ? '-' : h(record.roles.collect(&:name).sort.join(', '))
  end

end
