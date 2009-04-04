# -*- coding: utf-8 -*-

# Monkey patch AR code to retain the actual error reported by associated objects.
# Adapted from http://rails.lighthouseapp.com/projects/8994/tickets/247-validates_associated-detailed-validation-error-messages-on-associations

module ActiveRecord
  module Validations
    module ClassMethods
      def validates_associated(*attr_names)
        configuration = { :message => nil, :on => :save }
        configuration.update(attr_names.extract_options!)

        validates_each(attr_names, configuration) do |record, attr_name, associate|
          associations = associate.is_a?(Array) ? associate : [associate]
          associations.each do |association|
            if association && !association.valid?
              if configuration[:message]
                record.errors.add(attr_name, configuration[:message])
              else
                record.errors.add(attr_name, ActiveRecord::Errors.default_error_messages[:invalid])
                association.errors.each do |error_name, error_value|
                  record.errors.add(error_name, error_value)
                end
              end
            end
          end
        end
      end
    end
  end
  module Associations
    module ClassMethods
      def add_multiple_associated_save_callbacks(association_name)
        method_name = "validate_associated_records_for_#{association_name}".to_sym
        define_method(method_name) do
          association = instance_variable_get("@#{association_name}")
          if association.respond_to?(:loaded?)
            if new_record?
              association
            else
              association.select { |record| record.new_record? }
            end.each do |record|
              #errors.add "#{association_name}" unless record.valid?
              #debugger
              unless record.valid?
                record.errors.each do |error_name, error_value|
                  errors.add(error_name, error_value)
                end
              end
            end
          end
        end

        validate method_name
        before_save("@new_record_before_save = new_record?; true")

        after_callback = <<-end_eval
          association = instance_variable_get("@#{association_name}")

          records_to_save = if @new_record_before_save
            association
          elsif association.respond_to?(:loaded?) && association.loaded?
            association.select { |record| record.new_record? }
          else
            []
          end

          records_to_save.each { |record| association.send(:insert_record, record) } unless records_to_save.blank?

          # reconstruct the SQL queries now that we know the owner's id
          association.send(:construct_sql) if association.respond_to?(:construct_sql)
        end_eval
        
        # Doesn't use after_save as that would save associations added in after_create/after_update twice
        after_create(after_callback)
        after_update(after_callback)
      end
    end
  end
end
