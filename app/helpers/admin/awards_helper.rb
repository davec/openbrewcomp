# -*- coding: utf-8 -*-

module Admin::AwardsHelper

  def point_qualifier_column(record)
    record.point_qualifier? ? "Yes" : "No"
  end

  def styles_column(record)
    if record.styles.blank?
      '<b>Add Styles</b>'
    elsif controller.action_name == 'show'
      h(record.styles.sort_by{|s| [s.bjcp_category,s.bjcp_subcategory]}.collect(&:to_label).join(', '))
    else
      num_to_show = 3
      styles = record.styles.sort_by{|s| [s.bjcp_category,s.bjcp_subcategory]}.first(num_to_show+1).collect(&:to_label)
      styles[num_to_show] = '…' if styles.length == num_to_show+1  # replace the Nth value with a horizontal ellipsis (U2026)
      h(styles.join(', '))
    end
  end

  def category_form_column(record, input_name)
    categories = Category.find(:all,
                               :order => 'position').collect {|c| [ c.name, c.id ]}
    select :record, :category_id, categories,
           { :prompt => '- Select a category -' },
           { :name => input_name + '[id]' }
  end

end
