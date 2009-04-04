# -*- coding: utf-8 -*-

class Club < ActiveRecord::Base
  include ExportHelper

  has_many :entrants
  has_many :entries, :through => :entrants

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false,
                          :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true

  ClubStruct = Struct.new(:id, :name)

  @@other = nil
  def self.other
    @@other = ClubStruct.new(-1, 'Other (please specify)') unless @@other
    @@other
  end

  @@independent = nil
  def self.independent
    @@independent = Club.find_by_name('Independent') unless @@independent
    @@independent
  end

  # Export the table
  def self.export(format)
    case format
    when 'csv'
      to_csv(:columns => [ 'id', 'name' ],
             :conditions => [ 'id <> ?', other.id ])
    when 'yml', 'yaml'
      to_yaml
    else
      raise ArgumentError, "Invalid format: #{format}"
    end
  end

  def authorized_for_destroy?
    # Can only destroy if there are no entries associated with this club
    entries.empty?
  end

  protected

    def before_validation
      name.squish! unless name.nil?
    end

end
