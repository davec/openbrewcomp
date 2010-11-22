# -*- coding: utf-8 -*-

module Admin::CategoriesHelper

  def is_public_column(record)
    record.is_public? ? 'Yes' : 'No'
  end

  def awards_column(record)
    if record.awards.blank?
      '<b>Add Awards</b>'
    else
      num_to_show = 3
      awards = sorted_awards(record).first(num_to_show+1).map(&:to_label)
      awards[num_to_show] = '…' if awards.length == num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
      h(awards.join(', '))
    end
  end

  def awards_show_column(record)
    return '-' if record.awards.blank?
    h(sorted_awards(record).map(&:to_label).join(', '))
  end

  private

    def sorted_awards(record)
      record.awards.sort_by{ |a| [a.category_id, a.position] }
    end

end
