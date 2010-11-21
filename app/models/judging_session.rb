# -*- coding: utf-8 -*-

class JudgingSession < ActiveRecord::Base

  has_many :flights

  validates_presence_of :description
  validates_uniqueness_of :description, :case_sensitive => false,
                          :message => 'already exists'
  validates_length_of :description, :maximum => 255, :allow_blank => true

  validates_presence_of :date

  validates_presence_of :position
  validates_presence_of :position, :message => 'already exists'
  validates_numericality_of :position, :only_integer => true, :allow_blank => true

  validate :ensure_start_time_earlier_than_end_time

  named_scope :current_and_past, { :conditions => [ 'date <= ?', Date.today ], :order => :position }

  def self.dates
    all(:select => 'DISTINCT date', :conditions => 'date IS NOT NULL', :order => 'date').map(&:date)
  end

  def to_label
    description
  end

  def flight_count
    flights.length
  end

  def completed_flight_count
    flights.select(&:completed?).length
  end

  def authorized_for_delete?
    # Users must be logged in to delete a judging session
    return false unless current_user
    # and logged-in users can generally delete judging sessions
    return true unless existing_record_check?
    # unless the judging session has assigned flights
    flights.empty?
  end

  protected

    def before_validation
      description.squish! unless description.nil?
      self.position = (JudgingSession.maximum(:position) || 0) + 1 if position.blank?
    end

    def ensure_start_time_earlier_than_end_time
      errors.add_to_base('The start time must be earlier than the end time.') unless start_time.nil? || end_time.nil? || start_time < end_time
    end

    def before_save
      tz = CompetitionData.instance.timezone
      unless tz.nil?
        self.start_time = tz.local_to_utc(start_time) unless start_time.blank?
        self.end_time = tz.local_to_utc(end_time) unless end_time.blank?
      end
    end

    def after_find
      tz = CompetitionData.instance.timezone
      unless tz.nil?
        self.start_time = tz.utc_to_local(start_time) unless start_time.blank?
        self.end_time = tz.utc_to_local(end_time) unless end_time.blank?
      end
    end

end
