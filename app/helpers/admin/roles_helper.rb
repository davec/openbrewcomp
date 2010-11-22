# -*- coding: utf-8 -*-

module Admin::RolesHelper

  def rights_column(record)
    return '-' if record.rights.nil?
    record.rights.
      map{ |r| r.to_label.sub(/\w+ (.*)/, '\1').titleize }.
      sort.
      uniq.
      map{ |r| h(r) }.
      join(', ')
  end

  def rights_show_column(record)
    return '-' if record.rights.nil?
    record.rights.
      group_by{|r| r.to_label.sub(/\w+ (.*)/, '\1')}.
      sort.
      map{|e| "#{h(e[1][0].to_label.sub(/\w+ (.*)/, '\1').titleize)} (#{e[1].map{|r| h(r.to_label.sub(/(\w+) .*/, '\1').capitalize)}.sort.join(', ')})"}.
      join('<br />')
  end

  def users_column(record)
    record.users.nil? ? '-' : h(record.users.map(&:login).sort.join(', '))
  end

  def options_for_association_conditions(association)
    if association.name == :users
      [ 'is_admin = ?', true ]
    else
      super
    end
  end

  def association_options_find(association, conditions = nil)
    if association.name == :users
      conditions = controller.send(:merge_conditions, conditions, ['is_admin = ?', true])
    end
    super(association, conditions)
  end

end
