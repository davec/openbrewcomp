# -*- coding: utf-8 -*-

class Flight < ActiveRecord::Base

  DEFAULT_MIN_ENTRIES = 4
  DEFAULT_MAX_ENTRIES = 12

  belongs_to :round
  belongs_to :award
  belongs_to :judging_session
  has_and_belongs_to_many :entries
  has_many :judgings, :dependent => :destroy
  has_many :judges, :through => :judgings
  has_many :scores, :dependent => :destroy

  validates_presence_of :name
  validates_length_of :name, :maximum => 60, :allow_blank => true

  validates_presence_of :round_id
  validates_associated :round

  validates_presence_of :award_id
  validates_associated :award

  validate :ensure_no_duplicate_judges
  validate :ensure_judging_session_if_complete
  validate :ensure_at_least_two_judges_if_complete

  attr_accessor :status
  attr_reader :assigned_time, :completed_time
  attr_reader :judging_judges, :judging_steward

  def entry_count
    (round == Round.first && completed? && !pushed?) ?
      "#{entries.length} (#{entries.select(&:second_round?).length})" :
      entries.length
  end

  def status_label
     pushed? ? 'Pushed' : FlightStatus.new(self.status).label
  end

  def max_judges
    round == Round.bos ? (entries.length < 15 ? 3 : 5) : 4
  end

  def self.bos_flights
    Flight.find(:all, :conditions => [ 'round_id = ?', Round.bos.id ])
  end

  def authorized_for?(action)
    if action[:action] == 'print'
      @status != FlightStatus::COMPLETED
    elsif action[:action] == 'push'
      !protected? && round == Round.first && award.flights.length == 1
    else
      super
    end
  end

  # All flights currently assigned
  def self.flights_in_progress
    find(:all, :conditions => [ 'assigned = ?', true ])
  end

  # All flights marked complete, except for first-round flights pushed to second round
  def self.flights_completed
    first_round_flights = find(:all,
                               :joins => 'INNER JOIN rounds ON rounds.id = flights.round_id',
                               :conditions => "rounds.position = #{Round.first.position}")
    pushed_flight_ids = first_round_flights.collect(&:id) -
      Award.find_awards_with_multiple_first_round_flights.collect{|award| award.flights.collect{|flight| flight.id if flight.round == Round.first}}.flatten.compact

    find(:all,
         :joins => 'INNER JOIN rounds ON rounds.id = flights.round_id',
         :conditions => [ 'completed = ? AND flights.id NOT IN (?) AND rounds.position <> ?',
                          true, pushed_flight_ids, Round.bos.position ])
  end

  def authorized_for_update?
    # Users must be logged in to update a flight
    return false unless current_user
    # and logged-in users can generally update flights
    return true unless existing_record_check?
    # and the "master list" can update regardless of any other restrictions
    return true if Controller.is_full_list? && !pushed?
    # but first-round flights cannot be updated if the award's second-round flight is protected
    return false if round == Round.first &&
      self.award.flights.detect{|f| f.round == Round.second && f.protected?}
    # nor can second-round flights be updated if the corresponding best-of-show flight is protected
    return false if round == Round.second &&
      Flight.find(:all,
                  :select => 'f.*',
                  :joins => 'AS f INNER JOIN rounds AS r ON (r.id = f.round_id)',
                  :conditions => [ 'r.position = ?', Round.bos.position ]).detect{|f| f.entries.detect{|e| e.style.award_id == self.award.id} && f.protected?}
    # otherwise updates are allowed
    true
  end

  def judging_session_authorized?
    !pushed?
  end

  def judgings_authorized?
    !pushed?
  end

  def entries_authorized?
    !pushed?
  end

  def assigned_time_authorized?
    !pushed?
  end

  def completed_time_authorized?
    !pushed?
  end

  #def entry_count_authorized?
  #  !Controller.is_full_list?
  #end

  def assigned_authorized_for_read?
    Controller.is_full_list?
  end

  def completed_authorized_for_read?
    Controller.is_full_list?
  end

  def protected?
    self.assigned? || self.completed?
  end

  def unassigned?
    !protected?
  end

  def authorized_for_destroy?
    # Users must be logged in to delete a flight
    return false unless current_user
    # and logged-in users can generally delete flights
    return true unless existing_record_check?
    # unless the flight has been assigned or completed
    !protected?
  end

  protected

    def before_validation
      return unless status

      flight_status = FlightStatus.new(status)
      if flight_status.unassigned?
        self.assigned = false
        self.completed = false
      elsif flight_status.assigned?
        self.completed = false
        self.assigned = true
      elsif flight_status.completed?
        self.assigned = false
        self.completed = true
      else
        errors.add_to_base("Status must be #{FlightStatus.key_value_pairs.values.to_sentence(:words_connector => 'or')}")
      end
      true
    end

    def after_find
      self.status = flight_status
      tz = CompetitionData.instance.timezone
      unless tz.nil?
        @assigned_time = tz.utc_to_local(assigned_at) unless assigned_at.blank?
        @completed_time = tz.utc_to_local(completed_at) unless completed_at.blank?
      else
        @assigned_time = assigned_at unless assigned_at.blank?
        @completed_time = completed_at unless completed_at.blank?
      end

      flight_panel = Judging.find(:all,
                                  :joins => 'INNER JOIN judges ON judges.id = judgings.judge_id',
                                  :conditions => [ 'flight_id = ?', id ],
                                  :order => 'judges.last_name||judges.first_name||judges.middle_name').partition{|p| p.role == Judging::ROLE_JUDGE}
      @judging_judges = flight_panel[0]
      @judging_steward = flight_panel[1][0]  # There's only one steward per flight
    end

    def before_save
      name.squish! unless name.nil?
    end

    def before_update
      if unassigned?
        # If the status is reverted to unassigned, zap a assigned_at value.
        self.assigned_at = nil
      elsif assigned? && assigned_at.nil?
        # Only set assigned_at when the status is changed from unassigned to
        # assigned.
        self.assigned_at = Time.now.utc
      end

      if !completed?
        # If the status is reverted from completed, zap the completed_at value.
        self.completed_at = nil
      elsif completed? && completed_at.nil?
        # Only set completed_at when the status is changed from assigned (or,
        # less likely, unassigned) to completed.
        self.completed_at = Time.now.utc
      end
    end

    def after_save
      self.status = flight_status
    end

  private

    def ensure_no_duplicate_judges
      errors.add_to_base("A judge may only be assigned once to the judge panel.") unless judgings.collect{|j| j.judge.id}.uniq.length == judgings.length
    end

    def flight_status
      FlightStatus.new(assigned? ? FlightStatus::ASSIGNED : completed? ? FlightStatus::COMPLETED : FlightStatus::UNASSIGNED).key
    end

    def ensure_at_least_two_judges_if_complete
      errors.add_to_base('At least two judges must be selected') if completed and judgings.select{|j| j.role == Judging::ROLE_JUDGE}.length < 2
    end

    def ensure_judging_session_if_complete
      errors.add_to_base('A judging session must be selected') if completed and judging_session.nil?
    end

    def pushed?
      round && round == Round.first &&
        completed? &&
        award.flights.select{|f| f.round == Round.first}.length == 1 &&
        entries.all?(&:second_round?)
    end

end
