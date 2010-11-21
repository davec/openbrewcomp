# -*- coding: utf-8 -*-

class Round < ActiveRecord::Base

  # TODO: How to handle a different set of rounds.  We specifically reference
  # first, second, and BOS rounds in various parts of the code, but additional
  # rounds will very likely break stuff.  Similarly, removal of one of these 3
  # defined rounds will also cause problems.

  FIRST = 1
  SECOND = 2
  BOS = 3

  has_many :flights

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false, :message => 'already exists'
  validates_length_of :name, :maximum => 20, :allow_blank => true
  
  validates_presence_of :position
  validates_uniqueness_of :position, :message => 'already exists'
  validates_numericality_of :position, :only_integer => true, :allow_blank => true

  def self.first
    Round.find_by_position(FIRST)
  end

  def self.second
    Round.find_by_position(SECOND)
  end

  def self.bos
    Round.find_by_position(BOS)
  end

  def self.completed?(round_number)
    rounds = Round.all(:include => :flights, :conditions => [ 'position IN (?)', (1..round_number) ]) rescue nil
    raise ArgumentException if rounds.nil?
    rounds.all?{ |round|
      round.flights.size > 0 && round.flights.all?{ |flight| flight.completed? }
    }
  end

  def self.has_flights?(round_number)
    Flight.count(:all,
                 :joins => 'AS f INNER JOIN rounds AS r ON (r.id = f.round_id)',
                 :conditions => [ 'r.position = ?', round_number ]) > 0
  end

  def self.unassigned_flights?(round_number)
    Flight.count(:all,
                 :joins => 'AS f INNER JOIN rounds AS r ON (r.id = f.round_id)',
                 :conditions => [ 'r.position = ? AND f.assigned = ? AND f.completed = ?', round_number, false, false ]) > 0
  end

  def authorized_for_delete?
    # Can only delete if there are no associated flights
    flights.empty?
  end

  protected

    def before_validation
      name.squish! unless name.nil?
      self.position = (Round.maximum(:position) || 0) + 1 if position.blank?
    end

    def validate
      errors.add(:position, 'must be positive') if position.kind_of?(Integer) && position < 0
    end

end
