# -*- coding: utf-8 -*-

class Role < ActiveRecord::Base
  include ExportHelper

  has_and_belongs_to_many :users
  has_and_belongs_to_many :rights

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false,
                                 :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true
  validates_length_of :description, :maximum => 255, :allow_blank => true

  # Export the table
  def self.export(format)
    case format
    when 'csv'
      to_csv(:columns => [ 'id', 'name', 'description' ])
    when 'yml', 'yaml'
      to_yaml
    else
      raise ArgumentError, "Invalid format: #{format}"
    end
  end

  protected

    def before_validation
      name.squish! unless name.nil?
      description.squish! unless description.nil?
    end

end
