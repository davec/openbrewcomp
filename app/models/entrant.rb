# -*- coding: utf-8 -*-

class Entrant < ActiveRecord::Base
  include ExportHelper

  has_many :entries, :dependent => :destroy
  belongs_to :user
  belongs_to :club
  belongs_to :region
  belongs_to :country

  validates_presence_of :club_id
  validates_presence_of :club_name, :if => lambda { |e| e.club_id == Club.other.id }
  validates_presence_of :team_name, :if => lambda { |e| e.is_team? }

  validates_length_of :first_name,   :maximum =>  80, :allow_blank => true
  validates_length_of :middle_name,  :maximum =>  80, :allow_blank => true
  validates_length_of :last_name,    :maximum =>  80, :allow_blank => true
  validates_length_of :team_name,    :maximum =>  80, :allow_blank => true
  validates_length_of :team_members, :maximum => 255, :allow_blank => true
  validates_length_of :address1,     :maximum =>  80, :allow_blank => true
  validates_length_of :address2,     :maximum =>  80, :allow_blank => true
  validates_length_of :address3,     :maximum =>  80, :allow_blank => true
  validates_length_of :address4,     :maximum =>  80, :allow_blank => true
  validates_length_of :city,         :maximum =>  80, :allow_blank => true
  validates_length_of :email,        :maximum => 100, :allow_blank => true
  validates_length_of :phone,        :maximum =>  40, :allow_blank => true

  validates_format_of :email, :allow_blank => true,
                              :with => Authentication.email_regex,
                              :message => Authentication.bad_email_message

  validate :validate_presence_of_name_for_individual_entrant
  validate :validate_street_address
  validate :validate_city
  validate :validate_region
  validate :validate_postcode
  validate :ensure_either_email_or_phone_provided

  attr_accessor :club_name

  def name
    is_team? ? team_name : [ first_name, middle_name, last_name ].delete_if(&:blank?).join(' ')
  end

  def last_name_with_comma
    last_name + ',' unless last_name.blank?
  end

  def dictionary_name
    is_team? ? team_name : [ last_name_with_comma, first_name, middle_name ].delete_if(&:blank?).join(' ')
  end

  def expanded_name
    returning String.new do |v|
      v << name
      v << " (#{team_members})" if is_team? && !team_members.blank? && team_members != team_name
    end
  end

  def address
    [ address1, address2, address3, address4 ].delete_if(&:blank?).join("\n")
  end

  def postal_address(options = {})
    addr = eval country.address_format
    maybe_include_country = options[:include_country].nil? || options[:include_country]
    if maybe_include_country and Country.include_country_in_address?(country.country_code)
      addr << "\n"
      if country.country_address_name.nil?
        addr << country.name.sub(/\([^)]*\)$/,'').squish.upcase
      else
        addr << country.country_address_name.upcase
      end
    end
    addr.strip.squeeze("\n")
  end

  # Export settings
  self.csv_columns = [ 'id', 'name', 'is_team', 'team_members', 'address1', 'address2', 'city', 'region_id', 'country_id', 'postcode', 'email', 'phone', 'club_id' ]

  def authorized_for_delete?
    # Users must be logged in to delete entrants
    return false unless current_user
    # and logged-in users can generally delete entrants
    return true unless existing_record_check?
    # and users with delete rights can delete entries in the admin interface
    return current_user.roles.detect{|role|
             role.rights.detect{|right|
               right.controller == 'entrants' && right.action == 'delete'
             }
           } if Controller.admin_view?
    # unless a bottle code has been assigned to one or more of the entrant's
    # entries.
    self.entries.checked_in.empty?
  end

  protected

    def after_initialize
      # Default the club to "Independent" if not already specified
      self.club_id = Club.independent.id unless club_id
    end

    def before_validation
      [ first_name, middle_name, last_name, team_name, team_members,
        address1, address2, address3, address4, city, postcode, phone, email ].each do |v|
        v.send('squish!') unless v.send('nil?')
      end

      if !region_id.nil?
        self.region = Region.find(region_id)
        self.country = region.country
      elsif !country_id.nil?
        self.country = Country.find(country_id)
      end
    end

    def after_validation
      self.club = Club.find(club_id) if club_id != Club.other.id
      # Reset the irrelevant columns (so we don't run into trouble
      # in case we stumble across a person's name for a team).
      if is_team?
        self.first_name = self.middle_name = self.last_name = ''
      else
        self.team_name = self.team_members = ''
      end
    end

    def before_save
      if club_id == Club.other.id && !club_name.blank?
        club_name.squish!

        # TODO: Need more sophisticated checking for similar names.

        # This doesn't quite do what we want since there's no way to check
        # for case-insenitive matches.
        #self.club = Club.find_or_create_by_name(club_name)

        record = Club.first(:conditions => [ 'LOWER(name) = ?', club_name.downcase ])
        record = Club.create(:name => club_name) if record.nil?
        self.club = record
      end
    end

    def validate_presence_of_name_for_individual_entrant
      # The entrant is either an individual (with no team name) or a team
      # (with a team name and an optional individual's name).  Additionally,
      # an entrant must specify either an email address or a phone number.
      # Depending on the entrant's country of residence, a region code (e.g.,
      # state or province) and valid postal code must be specified.

      # Validate the individual's name (we accept a bare first or last name)
      if !is_team? && first_name.blank? && last_name.blank?
        errors.add_to_base("A name is required")
      end
    end

    def validate_street_address
      errors.add_to_base("Street address #{I18n.t('activerecord.errors.messages.blank')}") if address.blank? && !country.nil? && country.address_required?
    end

    def validate_city
      errors.add(:city, I18n.t('activerecord.errors.messages.blank')) if city.blank? && !country.nil? && country.city_required?
    end

    def validate_region
      if country.nil? || country.region_required?
        region_name = country.nil? ? "state" : country.region_name.split('/').to_sentence(:words_connector => "or")
        if region_id.nil?
          # We need to handle a special case for Ireland: The county name is not
          # required if the city name is the same as the county name.  (If no
          # county is selected, we obviously can't match the city and county
          # names, but we can see if the city name is contained in the list of
          # counties.) We also need to adjust for the district number in Dublin
          # addresses; we'll take a shortcut, however, by just taking the first
          # word of the city string since all counties in Ireland are a single
          # word anyway.

          errors.add_to_base("A #{region_name} is required") \
            unless !country.nil? &&
                   country.country_code == 'IE' &&
                   !city.blank? &&
                   !Region.find_by_country_id_and_name(country.id, city.split(' ')[0]).nil?
        else
          region = Region.find(region_id)
          if region.nil?
            errors.add(:region_id, I18n.t('activerecord.errors.messages.invalid'))
          elsif !region.nil? && !country_id.nil? && region.country_id != country_id
            errors.add_to_base("#{region.name} is not valid for #{country.name}")
          else
            self.region = region if region_id > 0
            self.country = region.country
          end
        end
      end
    end

    def validate_postcode
      if country.nil? || country.postcode_required?
        postcodetype = country.nil? || Country.use_us_addressing?(country.country_code) ? "Zip" : "Postal"
        if postcode.blank? && (country.nil? || !country.address_format.index('{postcode}').nil?)
          errors.add_to_base("#{postcodetype} code #{I18n.t('activerecord.errors.messages.blank')}")
        elsif !country.nil?
          if !country.validate_postcode(postcode)
            errors.add_to_base("#{postcodetype} code #{I18n.t('activerecord.errors.messages.invalid')}")
          else
            self.postcode = country.canonicalize_postcode(postcode)
          end
        end
      end
    end

    def ensure_either_email_or_phone_provided
      if email.blank? && phone.blank?
        errors.add_to_base("Either an email address or phone number is required")
      end
    end

end
