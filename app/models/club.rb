# -*- coding: utf-8 -*-

class Club < ActiveRecord::Base
  include ExportHelper

  has_many :entrants
  has_many :entries, :through => :entrants

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false,
                          :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true

  @@other = Struct.new(:id, :name).new(-1, 'Other (please specify)')
  cattr_reader :other

  @@independent = nil
  def self.independent
    @@independent ||= Club.find_by_name('Independent')
  end

  # Export settings
  self.csv_columns = [ 'id', 'name' ]

  # Export the table
  def self.export(format, options = {})
    options = options.merge(:conditions => [ 'id <> ?', other.id ]) if format == 'csv'
    super(format, options)
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
