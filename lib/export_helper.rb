# -*- coding: utf-8 -*-

require 'faster_csv'

module ExportHelper
  def self.included(base) # :nodoc:
    base.class_inheritable_accessor :csv_columns
    base.csv_columns = nil

    base.extend ClassMethods
  end

  module ClassMethods
    # Export the table
    def export(format, options = {})
      raise ArgumentError, "Invalid format: #{format}" unless respond_to?("to_#{format}", true)
      send("to_#{format}", options)
    end

    private

      # CSV-formatted exports
      def to_csv(options = {})
        FasterCSV.generate(:row_sep => "\n") do |csv|
          csv << csv_columns
          find(:all,
               :select => options[:select],
               :joins => options[:joins],
               :conditions => options[:conditions],
               :order => options[:order] || 'id ASC').each do |record|
            csv << csv_columns.inject([]){|row,col|
              value = record[col] || (record.respond_to?(col) ? record.send(col) : record[col])
              row << (value.blank? ? nil : (value.respond_to?(:tr) ? value.tr("\n", "\r") : value))
            }
          end
        end
      end

      # Raw exports
      def to_raw(options = {})
        i = '0'
        find(:all, options).inject({}){|hash, record|
          hash["#{table_name}_#{i.succ!}"] = record.attributes
          hash
        }
      end

      # YAML-formatted exports
      def to_yaml(options = {})
        to_raw.to_yaml
      end

      alias :to_yml :to_yaml
  end

end
