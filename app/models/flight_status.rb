# -*- coding: utf-8 -*-

class FlightStatus
  attr_accessor :key

  UNASSIGNED = '0'
  ASSIGNED   = '1'
  COMPLETED  = '2'

  @@settings = { UNASSIGNED => 'Unassigned',
                 ASSIGNED   => 'Assigned',
                 COMPLETED  => 'Completed' }.freeze

  def initialize(key)
    @key = key
  end

  def label
    @@settings[@key] || 'Unknown'
  end

  def unassigned?
    @key == UNASSIGNED
  end

  def assigned?
    @key == ASSIGNED
  end

  def completed?
    @key == COMPLETED
  end

  def self.key_value_pairs
    @@settings.sort
  end

end
