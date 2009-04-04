# -*- coding: utf-8 -*-

module AdministrationHelper

  def form_element_input_options(column_name, scope_class, options = {})
    if column_name.is_a?(String) || column_name.is_a?(Symbol)
      # Called from a helper override
      input_name = column_name.to_s
      klass = scope_class

      raise ArgumentException, "'#{input_name}' is invalid" unless input_name =~ /record([^\[]*)\[([^\]]*)\]/

      scope, name = $1, $2
      scope = nil if scope.blank?
      column = ActiveScaffold::DataStructures::Column.new(name, klass)
      active_scaffold_input_options(column, scope).merge(options)
    elsif column_name.is_a?(ActiveScaffold::DataStructures::Column)
      # Called from a partial overrride
      column = column_name
      scope = scope_class

      active_scaffold_input_options(column, scope).merge(options)
    elsif
      raise ArgumentException, "Unknown argument type: #{column_name.class.to_s}"
    end
  end

  def pretty_tag_value(tag_value)
    # Taken from form_helper.rb
    tag_value.to_s.gsub(/\s/, "_").gsub(/\W/, "").downcase
  end

  private

    def page_title
      @page_title || "#{competition_name} Administration :: #{@controller.controller_name.titleize}"
    end

end
