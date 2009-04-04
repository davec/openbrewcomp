# -*- coding: utf-8 -*-

class StyleInfo
  attr_accessor :key

  NO_KEY       = 'n'.freeze
  OPTIONAL_KEY = 'o'.freeze
  REQUIRED_KEY = 'r'.freeze

  @@settings = { NO_KEY       => 'No',
                 OPTIONAL_KEY => 'Optional',
                 REQUIRED_KEY => 'Required' }

  def initialize(key)
    @key = key
  end

  def label
    @@settings[@key] || 'Unknown'
  end

  def required?
    @key == REQUIRED_KEY
  end

  def optional?
    @key == OPTIONAL_KEY
  end

  def self.key_value_pairs
    @@settings.sort
  end

end
