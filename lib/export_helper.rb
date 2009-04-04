# -*- coding: utf-8 -*-

require 'faster_csv'

module ExportHelper
  def self.append_features(base) # :nodoc:
    super
    base.extend ClassMethods
  end

  module ClassMethods
    def to_csv(options = {})
      FasterCSV.generate(:row_sep => "\n") do |csv|
        csv << options[:columns]
        find(:all,
             :select => options[:select],
             :joins => options[:joins],
             :conditions => options[:conditions],
             :order => options[:order] || 'id ASC').each do |record|
          #csv << options[:columns].inject([]){|row,col| row << (record[col].blank? ? nil : (record[col].respond_to?(:tr) ? record[col].tr("\n", "\r") : record[col]))}
          csv << options[:columns].inject([]){|row,col|
            value = record[col] || (record.respond_to?(col) ? record.send(col) : record[col])
            row << (value.blank? ? nil : (value.respond_to?(:tr) ? value.tr("\n", "\r") : value))
          }
        end
      end
    end

    def to_yaml
      find(:all).inject({}){|hash, record|
        hash["record_#{record.attributes['id']}"] = record.attributes.delete_if{|k,v| k == 'lock_version'}
        hash
      }.to_yaml
    end
  end

end
