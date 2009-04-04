# -*- coding: utf-8 -*-

class PointAllocation < ActiveRecord::Base

  FORMAT_REGEX = /\A[0-9]{1,2}(\.[05])?\z/
  FORMAT_ERROR = 'must be a positive decimal number in half point increments (e.g., 0.5, 1.0)'

  validates_presence_of :min_entries
  validates_uniqueness_of :min_entries, :message => 'already exists'
  validates_numericality_of :min_entries, :only_integer => true, :allow_blank => true

  validates_presence_of :max_entries
  validates_uniqueness_of :max_entries, :message => 'already exists'
  validates_numericality_of :max_entries, :only_integer => true, :allow_blank => true

  validates_presence_of :organizer
  validates_numericality_of :organizer, :allow_blank => true
  validates_format_of :organizer, :allow_blank => true,
                      :with => FORMAT_REGEX, :message => FORMAT_ERROR

  validates_presence_of :staff
  validates_numericality_of :staff, :allow_blank => true
  validates_format_of :staff, :allow_blank => true,
                      :with => FORMAT_REGEX, :message => FORMAT_ERROR

  validates_presence_of :judge
  validates_numericality_of :judge, :allow_blank => true
  validates_format_of :judge, :allow_blank => true,
                      :with => FORMAT_REGEX, :message => FORMAT_ERROR


  validate :validate_entries_range

  def to_label
    "Competition Size Between #{min_entries} and #{max_entries} Entries"
  end

  def self.available_staff_points
    competition_points.staff
  end

  def self.max_judge_points
    competition_points.judge
  end

  def self.organizer_points
    competition_points.organizer
  end

  protected

    def validate
      errors.add(:min_entries, 'must be positive') if min_entries.kind_of?(Integer) && min_entries < 0
      errors.add(:max_entries, 'must be positive') if max_entries.kind_of?(Integer) && max_entries < 0
    end

    def validate_entries_range
      unless min_entries.nil? || max_entries.nil?
        errors.add_to_base('The minimum entry count must be less than the maximum entry count') if min_entries >= max_entries
      end
    end

  private

    @@empty_points_data = PointAllocation.new(:min_entries => 0, :max_entries => 0, :organizer => 0.0, :staff => 0.0, :judge => 0.0)
    def self.competition_points
      PointAllocation.find(:first, :conditions => [ '? BETWEEN min_entries AND max_entries', Entry.checked_in.count ]) || @@empty_points_data
    end

end
