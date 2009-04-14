# -*- coding: utf-8 -*-

class Country < ActiveRecord::Base
  include ExportHelper

  has_many :regions, :dependent => :destroy
  has_many :entrants
  has_many :entries, :through => :entrants

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false,
                          :message => 'already exists'
  validates_length_of :name, :maximum => 80, :allow_blank => true

  validates_length_of :region_name, :maximum => 60, :allow_blank => true

  validates_presence_of :country_code
  validates_uniqueness_of :country_code,
                          :message => 'already exists'
  validates_format_of :country_code, :with => /\A[A-Z]{2}\z/, :allow_blank => true

  validates_presence_of :postcode_pattern,
                        :unless => lambda {|c| c.postcode_canonify.blank?}

  def regions_by_name
    Region.find(:all,
                :conditions => [ 'country_id = ?', self.id ],
                :order => 'name')
  end

  def validate_postcode(str)
    # If there's no pattern specified, allow anything through
    return true if self.postcode_pattern.nil?

    !Country.parse_regexp(self.postcode_pattern).match(str).nil?
  end

  def canonicalize_postcode(str)
    return nil unless validate_postcode(str)

    if self.postcode_canonify.blank?
      str
    else
      eval str.gsub(Country.parse_regexp(self.postcode_pattern), self.postcode_canonify)
    end
  end

  def address_required?
    # TODO: Some countries, e.g., Scotland, do not require a street address
    # because the city is sufficient to identify the location. This type of
    # situation is not handled here.
    /\{address(\.[^\}]*)?\}/ =~ address_format
  end

  def city_required?
    # NOTE: There are very few countries that do not require a city name
    # (Guatemala, Nauru, and British Antarctic Territory, to be precise).
    /\{city(\.[^\}]*)?\}/ =~ address_format
  end

  def region_required?
    /\{region(\.[^\}]*)?\}/ =~ address_format
  end

  def postcode_required?
    /\{postcode(\.[^\}]*)?\}/ =~ address_format
  end

  def self.use_us_addressing?(country_code)
    [ 'US', 'AS', 'FM', 'GU', 'MH', 'MP', 'PR', 'PW', 'UM', 'VI' ].include?(country_code)
  end

  # Does the country name need to be included in the postal address?
  def self.include_country_in_address?(country_code)
    # NOTE: Change this logic to match the country in which your competition is located.
    # TODO: Make this configurable from the admin UI

    # For the US and its territories
    ![ 'US', 'AS', 'FM', 'GU', 'MH', 'MP', 'PR', 'PW', 'UM', 'VI' ].include?(country_code)

    ## For Canada
    #country_code != 'CA'
  end

  # Export settings
  self.csv_columns = [ 'id', 'country_code', 'name' ]

  # Export the table
  def self.export(format, options = {})
    options = options.merge(:conditions => [ 'is_selectable = ?', true ]) if format == 'csv'
    super(format, options)
  end

  def authorized_for_destroy?
    # Can only destroy if there are no associated entrants
    entrants.empty?
  end

  protected

    def before_validation
      name.squish! unless name.nil?
      country_code.upcase! unless country_code.blank?
    end

  private

    def self.parse_regexp(str)
      return nil if str.blank?

      re = /^(\/([^\/]*)\/(.*))|(\%r\{(.*)\}(.*))/
      match_data = re.match(str)
      if match_data.nil?
        regexp = Regexp.new(str)
      else
        if !match_data[1].nil?
          re_value = match_data[2]
          re_flags = match_data[3]
        else
          re_value = match_data[5]
          re_flags = match_data[6]
        end
        re_options = 0
        re_flags.split(//).each do |f|
          case f
          when 'i'
            re_options |= Regexp::IGNORECASE
          when 'x'
            re_options |= Regexp::EXTENDED
          when 'm'
            re_options |= Regexp::MULTILINE
          end
        end
        regexp = Regexp.new(re_value, re_options)
      end
    end

end
