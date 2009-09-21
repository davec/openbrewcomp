# -*- coding: utf-8 -*-

class Award < ActiveRecord::Base
  include ExportHelper

  # Maximum number of entries by a single entrant in an award category.
  # Set MAX_ENTRIES = nil if you do not impose an entry limit.
  MAX_ENTRIES = 2

  has_many :styles, :dependent => :destroy
  has_many :flights, :dependent => :destroy
  belongs_to :category
  acts_as_list :scope => :category_id

  validates_associated :category
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false,
                          :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true

  validates_uniqueness_of :position, :scope => 'category_id',
                          :message => 'already exists'
  validates_numericality_of :position, :only_integer => true, :allow_blank => true

  # Export settings
  self.csv_columns = [ 'id', 'name', 'category_id' ]

  # Allocate flights and assign entries to them.
  # No action is taken if any flights already exist.
  def create_flights_and_assign_entries(min_entries, max_entries)
    raise ArgumentError unless min_entries > 0 && max_entries > min_entries
    return unless flights.empty?

    # Get all entries in this award category
    entries = Entry.all(:select => 'e.*',
                        :joins => 'AS e INNER JOIN styles AS s ON (s.id = e.style_id)',
                        :conditions => [ 'e.style_id IN (?) AND e.bottle_code IS NOT NULL', styles.collect(&:id) ])
    return if entries.empty?

    Flight.transaction do
      if entries.length <= max_entries
        # The simple case is when all entries fit into a single flight.
        flight = Flight.create(:name => "#{name} 1",
                               :award_id => id,
                               :round_id => Round.first.id)
        flight.entries.push(*entries)
        flights << flight
      else
        # Otherwise, the entries must be allocated to multiple flights.
        size_range = (min_entries..max_entries)
        flight_number = '0'

        # Group the entries by sub-style
        grouping = entries.group_by(&:style_id)

        # Pass 1: Assign sub-styles when all of them fit in a single flight.
        grouping.each do |style_id, group|
          if size_range.member?(group.length)
            flight = Flight.create(:name => "#{name} #{flight_number.succ!}",
                                   :award_id => id,
                                   :round_id => Round.first.id)
            flight.entries.push(*group)
            flights << flight
            grouping.delete(style_id)
          end
        end

        # Pass 2: Split sub-styles into multiple flights.
        grouping.each do |style_id, group|
          if size_range.member?(group.length)
            flight_count = divide(group.length, max_entries)
            flight_size = divide(group.length, flight_count)
            group.in_groups_of(flight_size).each do |group_entries|
              flight = Flight.create(:name => "#{name} #{flight_number.succ!}",
                                     :award_id => id,
                                     :round_id => Round.first.id)
              flight.entries.push(*group_entries.compact)
              flights << flight
            end
            grouping.delete(style_id)
          end
        end

        # Pass 3: Split remaining entries into multiple flights.
        remaining_entries = grouping.inject([]){|arr, (key, val)| arr << val}.flatten
        unless remaining_entries.empty?
          flight_count = divide(remaining_entries.length, max_entries)
          flight_size = divide(remaining_entries.length, flight_count)
          remaining_entries.in_groups_of(flight_size).each do |group_entries|
            flight = Flight.create(:name => "#{name} #{flight_number.succ!}",
                                   :award_id => id,
                                   :round_id => Round.first.id)
            flight.entries.push(*group_entries.compact)
            flights << flight
          end
        end
      end
    end
  end

  def create_second_round_flight
    return unless category.is_public?

    # Proceed only if
    # (1) first-round flights exist,
    # (2) a second-round flight has not already been allocated, and
    # (3) all first-round flights are complete.
    return if flights.empty? || flights.detect{|f| f.round == Round.second || (f.round == Round.first && !f.completed?)}

    # Get all second-round entries in this award category
    entries = Entry.find(:all,
                         :select => 'e.*',
                         :joins => 'AS e INNER JOIN styles AS s ON (s.id = e.style_id)',
                         :conditions => [ 'e.style_id IN (?) AND e.second_round = ?', styles.collect(&:id), true ])

    Flight.transaction do
      flight = Flight.create(:name => "#{name}",
                             :award_id => id,
                             :round_id => Round.second.id)
      flight.entries.push(*entries)
      flights << flight
    end
  end

  def awards_for_bos
    qualified_awards = Award.find(:all, :conditions => [ 'point_qualifier = ?', true ])
    award_groups = qualified_awards.partition{|a| Category::MEAD_CIDER_RANGE.member?(a.category.position)}
    return case name
           when /Beer/
             award_groups[1]
           when /Mead/
             award_groups[0]
           else
             qualified_awards
           end
  end

  def create_best_of_show_flight
    return if category.is_public?  # The BOS awards are "non-public"

    # Determine which awards comprise this particular BOS award
    award_group_for_bos = awards_for_bos

    # Proceed only if
    # (1) first- and second-round flights exist, and
    # (2) the majority of second-round flights are complete.
    return if award_group_for_bos.any?{|award|
      award.entry_count > 0 &&
      (award.flights.empty? ||  # No flights
       award.flights.detect{|flight| flight.round == Round.second }.nil?)  # No second round flight
    }
    complete, incomplete = award_group_for_bos.collect{|award|
      award.flights.select{|flight|
        flight.round == Round.second
      }
    }.flatten.partition{|flight| flight.completed?}
    if complete.length > incomplete.length
      # Get all first place entries in this award category
      entries = Entry.find(:all,
                           :select => 'e.*',
                           :joins => 'AS e INNER JOIN styles AS s ON (s.id = e.style_id)',
                           :conditions => [ 'e.style_id IN (?) AND e.place = 1',
                                            award_group_for_bos.collect{ |award|
                                              award.styles.collect(&:id)
                                            }.flatten ])

      Flight.transaction do
        flight = Flight.find_or_create_by_name(:name => "#{name}",
                                               :award_id => id,
                                               :round_id => Round.bos.id)
        if flight.entries.empty?
          flight.entries.push(*entries)
          flights << flight
        else
          flight.entries.push(*(entries - flight.entries))
        end
        if CompetitionData.instance.mcab?
          # Automatically flag MCAB QEs where the MCAB QS is not split into multiple awards
          entries.each do |entry|
            entry.update_attribute(:mcab_qe, true) if entry.style.mcab_style? && entry.style.award.category.awards.length == 1
          end
        end
      end
    end
  end

  def find_all_entrants
    # Get all entrants in this award category
    return if styles.nil?
    entrants = unless styles.empty?
                 # Non-BOS awards
                 Entrant.find(:all,
                              :select => 'b.*',
                              :joins => 'AS b INNER JOIN entries AS e ON (b.id = e.entrant_id) INNER JOIN styles AS s ON (s.id = e.style_id) INNER JOIN awards AS a ON (a.id = s.award_id)',
                              :conditions => [ 'a.id = ? AND e.bottle_code IS NOT NULL', id ])
               else
                 # Best-of-Show awards
                 category_ids = case name
                                when /Beer/
                                  Category::CATEGORY_RANGE.to_a - Category::MEAD_CIDER_RANGE.to_a
                                when /Mead/
                                  Category::MEAD_CIDER_RANGE.to_a
                                else
                                  Category::CATEGORY_RANGE.to_a
                                end
                 Entrant.find(:all,
                              :select => 'b.*',
                              :joins => 'AS b INNER JOIN entries AS e ON (b.id = e.entrant_id) INNER JOIN styles AS s ON (s.id = e.style_id) INNER JOIN awards AS a ON (a.id = s.award_id) INNER JOIN categories AS c ON (c.id = a.category_id)',
                              :conditions => [ 'a.point_qualifier = ? AND c.position IN (?) AND e.place = 1',
                                               true, category_ids ])
               end
    entrants.uniq.sort{|x,y| x.dictionary_name <=> y.dictionary_name}
  end

  def self.find_awards_with_multiple_first_round_flights
    # Get the awards with multiple first-round flights
    sql = 'SELECT f.award_id, a.* FROM ((awards AS a INNER JOIN flights AS f ON (a.id = f.award_id)) INNER JOIN rounds AS r ON (r.id = f.round_id))'
    sql << " WHERE r.position = #{Round.first.position}"
    sql << ' GROUP BY f.award_id, '
    sql << columns.collect{|c| "a.#{c.name}"}.join(', ')
    sql << ' HAVING COUNT(f.award_id) > 1'
    find_by_sql(sql)
  end

  def self.find_public_awards
    # Get all awards that do not belong to non-public categories
    find_awards(true)
  end

  def self.find_non_public_awards
    # Get all awards that do not belong to public categories
    find_awards(false)
  end
  def self.bos_awards
    find_non_public_awards
  end

  def authorized_for_destroy?
    # Can only destroy if there are no entries registered in this award category
    styles.all?{|s| s.entries.empty?}
  end

  # Return the number of (processed) entries for this award
  def entry_count
    Entry.count(:all,
                :joins => 'AS e INNER JOIN styles AS s ON (s.id = e.style_id)',
                :conditions => [ 'e.style_id IN (?) AND e.bottle_code IS NOT NULL', styles.collect(&:id) ])
  end

  protected

    def before_validation
      name.squish! unless name.nil?
    end

    def validate
      errors.add(:position, "must be positive") if position.kind_of?(Integer) && position < 0
    end

  private

    def divide(a, b)
      a / b + (a % b > 0 ? 1 : 0)
    end

    def self.find_awards(is_public)
      find(:all,
           :select => 'a.*',
           :joins => 'AS a INNER JOIN categories AS c ON c.id = a.category_id',
           :conditions => [ 'c.is_public = ?', is_public ],
           :group => %Q{c.position, a.position, #{columns.collect{|c| "a.#{c.name}" unless c.name == 'position'}.compact.join(', ')}},
           :order => 'c.position ASC, a.position ASC')
    end

end
