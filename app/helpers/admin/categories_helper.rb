# -*- coding: utf-8 -*-

module Admin::CategoriesHelper

  def is_public_column(record)
    record.is_public? ? 'Yes' : 'No'
  end

  def awards_column(record)
    if record.awards.nil?
      '-'
    elsif controller.action_name == 'show'
      h(record.awards.sort_by{|a| [a.category_id,a.position]}.collect(&:to_label).join(', '))
    else
      num_to_show = 3
      awards = record.awards.sort_by{|a| [a.category_id,a.position]}.first(num_to_show+1).collect(&:to_label)
      awards[num_to_show] = '…' if awards.length == num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
      h(awards.join(', '))
    end
  end

end
