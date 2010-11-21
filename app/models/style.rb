# -*- coding: utf-8 -*-

class Style < ActiveRecord::Base
  include ExportHelper

  composed_of :style_info, :mapping => [ %w(styleinfo key) ]

  belongs_to :award
  has_many :entries, :dependent => :destroy

  named_scope :classic_styles, :conditions => 'bjcp_category < 20'
  named_scope :base_styles, :conditions => 'bjcp_category < 29'
  named_scope :special_styles, :conditions => 'bjcp_category > 28'

  validates_associated :award
  validates_presence_of :name, :bjcp_category, :description_url
  validates_uniqueness_of :name, :case_sensitive => false,
                          :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true

  validates_numericality_of :bjcp_category, :only_integer => true, :allow_blank => true

  validates_inclusion_of :bjcp_category,
                         :in => Category::CATEGORY_RANGE,
                         :message => "must be between #{Category::CATEGORY_RANGE.first} and #{Category::CATEGORY_RANGE.last}",
                         :allow_blank => true

  validates_inclusion_of :bjcp_subcategory,
                         :in => Category::SUBCATEGORY_RANGE,
                         :message => "must be between #{Category::SUBCATEGORY_RANGE.first} and #{Category::SUBCATEGORY_RANGE.last}",
                         :allow_blank => true

  validates_format_of :description_url,
                      :with => /(\A(ftp|https?):\/\/.+)|(\A\/\w+\/\w+\z)/,
                      :message => "is not a properly formatted URL",
                      :allow_blank => true
  
  # Determine the number of bottles required for entries in this style category.
  # By default, a style that is eligible for Best-of-Show, i.e., one that is
  # a point qualifier, requires one more bottle than a style that is not
  # eligible for Best-of-Show.
  #
  # Change the return value to match the rules of your competition.
  def number_of_bottles_required
    point_qualifier? ? 3 : 2
  end

  def category
    [ bjcp_category, bjcp_subcategory ].join
  end

  def category_and_name
    "#{category} - #{name}"
  end

  # Get the "first time" style. This assumes that the style name matches the
  # regex /^first.time/i (or in SQL terms, 'first_time%'). If no such style is
  # found, a dummy record is returned (which avoids littering the code with
  # checks for a nil return from this method).
  def self.first_time
    Rails.cache.fetch(:first_time_style) { Style.find(:first, :conditions => "LOWER(name) LIKE 'first_time%'") || Struct.new(:id, :name, :bjcp_category, :bjcp_subcategory).new(-1, 'Dummy', 0, '') }
  end

  def first_time?
    Style.first_time && Style.first_time[:id] == id
  end

  # Export settings
  self.csv_columns = [ 'id', 'bjcp_category', 'bjcp_subcategory', 'name', 'award_id' ]

  def authorized_for_delete?
    # Can only delete if there are no entries registered in this style
    entries.empty?
  end

  protected

    def before_validation
      name.squish! unless name.nil?
      bjcp_subcategory.upcase! unless bjcp_subcategory.blank?
    end

    def validate_on_create
      if Style.find_by_bjcp_category_and_bjcp_subcategory(bjcp_category, bjcp_subcategory)
        errors.add_to_base("Style category #{bjcp_category}#{bjcp_subcategory} already exists")
      end
    end

end
