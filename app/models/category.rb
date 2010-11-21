# -*- coding: utf-8 -*-

class Category < ActiveRecord::Base
  include ExportHelper

  # BJCP only has 28 categories, but we allow up to 4 additional categories
  # Note: The best-of-show category position should be non-public and outside
  # the valid range for non-BOS categories.
  CATEGORY_RANGE = (1..32)
  MEAD_CIDER_RANGE = (24..28)
  SUBCATEGORY_RANGE = ('A'..'F')

  has_many :awards, :dependent => :destroy
  has_many :styles, :through => :awards

  named_scope :is_public, :conditions => { :is_public => true }

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false,
                          :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true

  validates_presence_of :position
  validates_uniqueness_of :position, :allow_blank => true,
                          :message => 'already exists'
  validates_inclusion_of :position, :allow_blank => true,
                         :in => CATEGORY_RANGE,
                         :message => "must be between #{CATEGORY_RANGE.begin} and #{CATEGORY_RANGE.end}",
                         :if => lambda { |c| c.is_public? }
  validates_exclusion_of :position, :allow_blank => true,
                         :in => CATEGORY_RANGE,
                         :message => "must not be between #{CATEGORY_RANGE.begin} and #{CATEGORY_RANGE.end}",
                         :if => lambda { |c| !c.is_public? }

  def name_with_index
    "#{position} – #{name}"
  end

  # Export settings
  self.csv_columns = [ 'id', 'name' ]

  def authorized_for_delete?
    # Can only delete if there are no entries registered in this category
    styles.all?{|s| s.entries.empty?}
  end

  protected

    def before_validation
      name.squish! unless name.nil?
      self.is_public = (is_public.to_s.blank? || !/^[^0fn]/i.match(is_public.to_s).nil?)
      true
    end

end
