# -*- coding: utf-8 -*-

class Region < ActiveRecord::Base
  include ExportHelper

  belongs_to :country
  has_many :entrants
  has_many :entries, :through => :entrants

  validates_associated :country

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => 'country_id',
                                 :case_sensitive => false,
                                 :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true

  validates_presence_of :region_code
  validates_uniqueness_of :region_code, :scope => 'country_id',
                                        :message => 'already exists'
  validates_format_of :region_code, :with => /\A[A-Z0-9]{1,6}\z/, :allow_blank => true

  validates_presence_of :country_id

  # Export settings
  self.csv_columns = [ 'id', 'region_code', 'name', 'country_id' ]

  # Export the table
  def self.export(format, options = {})
    options = options.merge(:select => 'r.id, r.region_code, r.name, r.country_id',
                            :joins => 'as r inner join countries as c on (c.id = r.country_id)',
                            :order => 'r.id ASC',
                            :conditions => [ 'c.is_selectable = ?', true ]) if format == 'csv'
    super(format, options)
  end

  def authorized_for_delete?
    # Can only delete if there are no associated entrants
    entrants.empty?
  end

  protected

    def before_validation
      name.squish! unless name.nil?
      region_code.upcase! unless region_code.blank?
    end

end
