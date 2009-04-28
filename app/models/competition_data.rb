# -*- coding: utf-8 -*-

require 'tzinfo'

class CompetitionData < ActiveRecord::Base
  set_table_name :competition_data

  validates_presence_of :name
  validates_length_of :name, :maximum => 255, :allow_blank => true

  validates_presence_of :local_timezone, :allow_nil => true
  validates_length_of :local_timezone, :maximum => 255, :allow_blank => true

  validates_format_of :competition_number, :allow_blank => true,
                      :with => /\A[1-9][0-9]{5}\z/,
                      :message => 'must be a 6 digit value, 100000 or greater'

  validate :validate_timezone
  validate :ensure_entry_registration_start_time_before_end_time
  validate :ensure_judge_registration_start_time_before_end_time

  before_validation :set_default_timezone_if_not_given

  REGISTRATION_STATUS_OPEN = 'is open'
  REGISTRATION_STATUS_FUTURE = 'is not yet available'
  REGISTRATION_STATUS_PAST = 'is closed'
  REGISTRATION_STATUS_UNKNOWN = 'is not available'

  # The times are stored in the DB as UTC, but processed by the user in the
  # local timezone.  Therefore, we need to keep the two in sync.
  attr_reader :entry_registration_start_time, :entry_registration_end_time
  attr_reader :judge_registration_start_time, :judge_registration_end_time
  attr_reader :registration_start_time, :registration_end_time
  attr_reader :competition_start_time, :timezone
  def entry_registration_start_time=(time)
    t = mktime(time)
    write_attribute(:entry_registration_start_time_utc, to_utc(t))
    @entry_registration_start_time = t
  end
  def entry_registration_start_time_utc=(time)
    t = mktime(time)
    write_attribute(:entry_registration_start_time_utc, t)
    @entry_registration_start_time = to_local(t)
  end
  def entry_registration_end_time=(time)
    t = mktime(time)
    write_attribute(:entry_registration_end_time_utc, to_utc(t))
    @entry_registration_end_time = t
  end
  def entry_registration_end_time_utc=(time)
    t = mktime(time)
    write_attribute(:entry_registration_end_time_utc, t)
    @entry_registration_end_time = to_local(t)
  end
  def judge_registration_start_time=(time)
    t = mktime(time)
    write_attribute(:judge_registration_start_time_utc, to_utc(t))
    @judge_registration_start_time = t
  end
  def judge_registration_start_time_utc=(time)
    t = mktime(time)
    write_attribute(:judge_registration_start_time_utc, t)
    @judge_registration_start_time = to_local(t)
  end
  def judge_registration_end_time=(time)
    t = mktime(time)
    write_attribute(:judge_registration_end_time_utc, to_utc(t))
    @judge_registration_end_time = t
  end
  def judge_registration_end_time_utc=(time)
    t = mktime(time)
    write_attribute(:judge_registration_end_time_utc, t)
    @judge_registration_end_time = to_local(t)
  end
  def competition_start_time=(time)
    t = mktime(time)
    write_attribute(:competition_start_time_utc, to_utc(t))
    @competition_start_time = t
  end
  def competition_start_time_utc=(time)
    t = mktime(time)
    write_attribute(:competition_start_time_utc, t)
    @competition_start_time = to_local(t)
  end
  def local_timezone=(local_timezone)
    write_attribute(:local_timezone, local_timezone)
    begin
      @timezone = TZInfo::Timezone.get(local_timezone || 'UTC')
    rescue
      # Nothing to do here, move along ...
    else
      # Now update the UTC times (leaving the local times fixed)
      write_attribute(:competition_start_time_utc,        to_utc(@competition_start_time))
      write_attribute(:entry_registration_start_time_utc, to_utc(@entry_registration_start_time))
      write_attribute(:entry_registration_end_time_utc,   to_utc(@entry_registration_end_time))
      write_attribute(:judge_registration_start_time_utc, to_utc(@judge_registration_start_time))
      write_attribute(:judge_registration_end_time_utc,   to_utc(@judge_registration_end_time))
    end
  end

  # NOTE: There should only be a single row in the table, so the
  # before_create and before_destroy methods must enforce the
  # single-row requirement.
  before_create :ensure_only_one_record
  before_destroy :deny_deletion

  # Prevent clone()ing, dup()ing, allocate()ing, or new()ing
  def clone
    raise TypeError, "Cannot clone a #{self.class} object"
  end
  def dup
    raise TypeError, "Cannot dup a #{self.class} object"
  end
  private_class_method :new, :allocate

  # Advise AS that creates and destroys are not allowed
  def authorized_for?(action)
    ![ :create, :destroy ].include?(action[:action].to_sym)
  end

  @@competition_data = nil
  def self.instance
    @@competition_data ||= CompetitionData.find_by_sql('SELECT * FROM competition_data').first
    @@competition_data
  end

  # Force a reload
  def self.reload!
    @@competition_data = CompetitionData.find_by_sql('SELECT * FROM competition_data').first
  end

  # Override the find method to return the class variable
  def self.find(*args)
    case args.first
    when :all then [ instance ]
    else           instance
    end
  end

  def to_label
    ''
  end

  def entry_registration_status
    now = Time.now.utc

    # WARNING: Watch the comparison order here
    entry_registration_status = if entry_registration_start_time_utc.nil? && entry_registration_end_time_utc.nil?
      REGISTRATION_STATUS_UNKNOWN
    elsif (entry_registration_start_time_utc.nil? && now < entry_registration_end_time_utc) ||
          (entry_registration_end_time_utc.nil? && now > entry_registration_start_time_utc) ||
          now.between?(entry_registration_start_time_utc, entry_registration_end_time_utc)
      REGISTRATION_STATUS_OPEN
    elsif now < entry_registration_start_time_utc
      REGISTRATION_STATUS_FUTURE
    else
      REGISTRATION_STATUS_PAST
    end
  end

  def judge_registration_status
    now = Time.now.utc

    # WARNING: Watch the comparison order here
    judge_registration_status = if judge_registration_start_time_utc.nil? && judge_registration_end_time_utc.nil?
      REGISTRATION_STATUS_UNKNOWN
    elsif (judge_registration_start_time_utc.nil? && now < judge_registration_end_time_utc) ||
          (judge_registration_end_time_utc.nil? && now > judge_registration_start_time_utc) ||
          now.between?(judge_registration_start_time_utc, judge_registration_end_time_utc)
      REGISTRATION_STATUS_OPEN
    elsif now < judge_registration_start_time_utc
      REGISTRATION_STATUS_FUTURE
    else
      REGISTRATION_STATUS_PAST
    end
  end

  def registration_status
    is_registration_open? \
      ? REGISTRATION_STATUS_OPEN \
      : is_registration_future? \
        ? REGISTRATION_STATUS_FUTURE \
        : is_registration_past? \
          ? REGISTRATION_STATUS_PAST \
          : REGISTRATION_STATUS_UNKNOWN
  end

  def is_entry_registration_open?
    entry_registration_status == REGISTRATION_STATUS_OPEN
  end

  def is_entry_registration_future?
    entry_registration_status == REGISTRATION_STATUS_FUTURE
  end

  def is_entry_registration_past?
    entry_registration_status == REGISTRATION_STATUS_PAST
  end

  def is_judge_registration_open?
    judge_registration_status == REGISTRATION_STATUS_OPEN
  end

  def is_judge_registration_future?
    judge_registration_status == REGISTRATION_STATUS_FUTURE
  end

  def is_judge_registration_past?
    judge_registration_status == REGISTRATION_STATUS_PAST
  end

  def is_registration_open?
    entry_registration_status == REGISTRATION_STATUS_OPEN ||
    judge_registration_status == REGISTRATION_STATUS_OPEN
  end

  def is_registration_future?
    entry_registration_status == REGISTRATION_STATUS_FUTURE &&
    judge_registration_status == REGISTRATION_STATUS_FUTURE
  end

  def is_registration_past?
    entry_registration_status == REGISTRATION_STATUS_PAST &&
    judge_registration_status == REGISTRATION_STATUS_PAST
  end

  def is_data_purge_allowed?
    # Allow data to be purged only before online registration starts
    # and after the competition is complete.
    registration_start_time_utc = [ entry_registration_start_time_utc,
                                    judge_registration_start_time_utc ].compact.min
    now = Time.now.utc
    now < (registration_start_time_utc || now.yesterday) || now.to_date > (competition_date || now.yesterday.to_date)
  end

  def to_utc(time)
    return time if @timezone.name == 'UTC' || time.nil?
    @timezone.local_to_utc(time)
  end

  def to_local(time)
    return time if @timezone.name == 'UTC' || time.nil?
    @timezone.utc_to_local(time)
  end

  # Create a Time object from the given object which may be a Time or any object
  # whose to_s method produces a string that is recognized as a time.  The
  # returned value is a UTC time.
  def mktime(time)
    return nil if time.blank?
    return time if time.is_a?(Time)
    Time.zone.parse(time.to_s) rescue nil
  end

  protected

    def after_find
      @timezone = TZInfo::Timezone.get(local_timezone || 'UTC') rescue TZInfo::Timezone.get('UTC')
      @competition_start_time  = to_local(competition_start_time_utc)
      @entry_registration_start_time = to_local(entry_registration_start_time_utc)
      @entry_registration_end_time   = to_local(entry_registration_end_time_utc)
      @judge_registration_start_time = to_local(judge_registration_start_time_utc)
      @judge_registration_end_time   = to_local(judge_registration_end_time_utc)
    end

    def validate_timezone
      # Validate the value of local_timezone
      unless local_timezone == 'UTC'
        begin
          tz = TZInfo::Timezone.get(local_timezone)
        rescue
          errors.add(:local_timezone, I18n.t('activerecord.errors.messages.invalid'))
        end
      end
    end

    def ensure_entry_registration_start_time_before_end_time
      # The registration start date must be before the end date
      unless entry_registration_start_time_utc.nil? ||
             entry_registration_end_time_utc.nil? ||
             entry_registration_start_time_utc < entry_registration_end_time_utc
        errors.add_to_base('The entry registration start time must be earlier than the entry registration end time')
      end
    end

    def ensure_judge_registration_start_time_before_end_time
      # The registration start date must be before the end date
      unless judge_registration_start_time_utc.nil? ||
             judge_registration_end_time_utc.nil? ||
             judge_registration_start_time_utc < judge_registration_end_time_utc
        errors.add_to_base('The judge registration start time must be earlier than the judge registration end time')
      end
    end

    def set_default_timezone_if_not_given
      self.local_timezone = 'UTC' if local_timezone.nil?
    end

    def ensure_only_one_record
      raise 'Only one competition data record is allowed.' unless CompetitionData.count == 0
    end

    def deny_deletion
      raise 'Deletion is not allowed.'
    end

end
