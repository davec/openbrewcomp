# -*- coding: utf-8 -*-

module Admin::RolesHelper

  def rights_column(record)
    if record.rights.nil?
      '-'
    elsif controller.action_name == 'show'
      record.rights.group_by{|r| r.to_label.sub(/\w+ (.*)/, '\1')}.sort.collect{|e| "#{h e[1][0].to_label.sub(/\w+ (.*)/, '\1').titleize} (#{e[1].collect{|r| h r.to_label.sub(/(\w+) .*/, '\1').capitalize}.sort.join(', ')})"}.join('<br />')
    else
      record.rights.collect{|r| h r.to_label.sub(/\w+ (.*)/, '\1').titleize}.sort.uniq.join(', ')
    end
  end

  def users_column(record)
    record.users.nil? ? '-' : h(record.users.collect(&:login).sort.join(', '))
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
