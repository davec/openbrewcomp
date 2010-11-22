# -*- coding: utf-8 -*-

class Judge < ActiveRecord::Base

  belongs_to :user
  belongs_to :club
  belongs_to :region
  belongs_to :country
  belongs_to :judge_rank
  has_many :judgings
  has_many :flights, :through => :judgings
  has_many :scores
  has_many :time_availabilities, :dependent => :destroy
  has_many :category_preferences, :dependent => :destroy

  named_scope :checked_in, :conditions => [ 'checked_in = ?', true ]
  named_scope :confirmed, :conditions => [ 'confirmed = ?', true ]
  named_scope :unconfirmed, :conditions => 'confirmed IS NULL'
  named_scope :has_email, :conditions => [ 'email IS NOT NULL AND email <> ?', '' ]
  named_scope :bjcp, :conditions => 'judge_number IS NOT NULL'
  named_scope :non_bjcp, :conditions => 'judge_number IS NULL'
  named_scope :order, lambda {|order| { :order => order } }

  validates_presence_of :club_name, :if => lambda { |a| a.club_id == Club.other.id }

  validates_length_of :first_name,  :maximum =>  80, :allow_blank => true
  validates_length_of :middle_name, :maximum =>  80, :allow_blank => true
  validates_length_of :last_name,   :maximum =>  80, :allow_blank => true
  validates_length_of :goes_by,     :maximum =>  80, :allow_blank => true
  validates_length_of :address1,    :maximum =>  80, :allow_blank => true
  validates_length_of :address2,    :maximum =>  80, :allow_blank => true
  validates_length_of :address3,    :maximum =>  80, :allow_blank => true
  validates_length_of :address4,    :maximum =>  80, :allow_blank => true
  validates_length_of :city,        :maximum =>  80, :allow_blank => true
  validates_length_of :email,       :maximum => 100, :allow_blank => true
  validates_length_of :phone,       :maximum =>  40, :allow_blank => true

  validates_format_of :email, :allow_blank => true,
                      :with => Authentication.email_regex,
                      :message => Authentication.bad_email_message
  validates_format_of :staff_points, :allow_nil => true,
                      :with => PointAllocation::FORMAT_REGEX,
                      :message => PointAllocation::FORMAT_ERROR
  validates_uniqueness_of :judge_number, :allow_blank => true,
                          :message => 'is already registered'

  validates_presence_of :judge_rank, :message => 'must be selected'
  validates_associated :judge_rank, :allow_nil => true

  validate :validate_presence_of_name
  validate :validate_postal_address
  validate :validate_judge_number
  validate :ensure_either_email_or_phone_provided
  validate :ensure_only_one_organizer
  validate :validate_staff_points

  attr_accessor :club_name

  # The following attributes cannot be set via bulk assignment
  attr_protected :staff_points, :organizer, :access_key, :checked_in, :confirmed

  # @is_admin_view is set by the controller when the record is instantiated to
  # provide the necessary information to the authorized_for_delete? method to
  # deterine whether the delete action is to be enabled in the view.
  attr_writer :is_admin_view

  def name
    [ first_name, middle_name, last_name ].delete_if(&:blank?).join(' ')
  end

  def last_name_with_comma
    last_name + ',' unless last_name.blank?
  end

  def dictionary_name
    [ last_name_with_comma, first_name, middle_name ].delete_if(&:blank?).join(' ')
  end

  def name_with_rank
    name + ' [' + (judge_rank.nil? ? '- NONE -' : judge_rank.description) + ']'
  end

  def dictionary_name_with_rank
    dictionary_name + ' [' + (judge_rank.nil? ? '- NONE -' : judge_rank.description) + ']'
  end

  def address
    [ address1, address2, address3, address4 ].delete_if(&:blank?).join("\n")
  end

  def postal_address
    if country_id.nil?
      addr = name
    else
      addr = eval country.address_format
      if Country.include_country_in_address?(country.country_code)
        addr << "\n"
        if country.country_address_name.nil?
          addr << country.name.sub(/\([^)]*\)$/,'').strip.upcase
        else
          addr << country.country_address_name.upcase
        end
      end
    end
    addr
  end

  include Comparable
  def <=>(other)
    dictionary_name.downcase <=> other.dictionary_name.downcase
  end

  attr_reader :steward_points

  def judge_points(include_bos_points = true)
    return earned_points if include_bos_points
    [ @judge_points, 1.0 ].min unless @judge_points == 0
  end

  def is_steward?
    @steward_points > 0.0
  end

  def is_judge?
    @judge_points > 0.0
  end

  def is_bos_judge?
    @bos_points > 0.0
  end

  def is_staff?
    staff_points > 0.0
  end

  # Return a numeric value to be used in a boolean sort
  def bos_judge_sort
    is_bos_judge? ? 1 : 0
  end

  def available_staff_points
    [ PointAllocation.organizer_points - earned_points,
      staff_points + Judge.unallocated_staff_points ].min
  end

  def self.unallocated_staff_points
    PointAllocation.available_staff_points - (Judge.sum(:staff_points) || 0)
  end

  def earned_points
    total = @judge_points + @bos_points
    total = [ total, 1.0 ].max unless total == 0
    total
  end

  def points
    return PointAllocation.organizer_points if organizer?
    staff_points + earned_points + @steward_points
  end

  def role
    roles = []
    if organizer?
      roles << 'Organizer'
    else
      roles << 'Staff' if is_staff?
      if is_steward?
        roles << 'Steward'
      else
        roles << 'Judge' if is_judge?
        roles << 'BOS' if is_bos_judge?
      end
    end
    rv = roles.join(' + ')
    rv << ' Judge' if rv == 'BOS'
    rv
  end

  def self.find_all_available
    Judge.checked_in.order('last_name, first_name, middle_name')
  end

  def self.organizer
    Judge.first(:conditions => [ 'organizer = ?', true ])
  end

  def self.email_count(options = {})
    scope_for_target(options[:target]).count
  end

  def self.email_invites(options = {})
    sent = failed = 0
    message = options.delete(:message)
    target  = options.delete(:target)
    scope_for_target(target).find_each(:batch_size => 100) do |judge|
      begin
        JudgeMailer.deliver_judge_invite(judge,
                                         format_message(message, judge),
                                         options)
        sent += 1
      rescue Exception => e
        failed += 1
        logger.error e.to_s
      end
    end
    [ sent, failed ]
  end

  def authorized_for_delete?
    # Users must be logged in to delete judges
    return false unless current_user
    # and logged-in users can generally delete judges
    return true unless existing_record_check?
    # unless the judge has already judged a flight
    flights.empty?
  end

  def flights_authorized_for_read?
    return true if new_record?
    existing_record_check? && !flights.empty?
  end

  protected

    def after_initialize
      # FIXME: This processing should be moved elsewhere, perhaps at the point
      # that a flight is updated after being marked complete with the various
      # point buckets stored in the judge's record.

      self.staff_points = attributes["staff_points"] || 0.0
      @judge_points = @steward_points = @bos_points = 0.0
      return if organizer? || new_record?

      judging_sessions = judgings.reject{|sess| sess.flight.judging_session.nil?}
      non_bos_sessions = judging_sessions.reject{|sess| sess.flight.round == Round.bos}
      bos_sessions = judging_sessions - non_bos_sessions

      # Determine if any BOS flights were judged and award the 0.5 point "bonus"
      @bos_points = 0.5 unless bos_sessions.empty? || bos_sessions.select{|sess| sess.role == Judging::ROLE_JUDGE}.empty?

      # Determine judge points:
      #
      # Judges earn 0.5 points per session, with a max of 1.5 points per day,
      # and a minimum of 1.0 points per competition.
      #
      # FIXME: Need to check daily max in the rare event that there are more
      # than 3 sessions in a day.
      #
      # TODO: Determine whether a BOS judge is allowed to exceed the 1.5 points
      # per day maximum.  If not, and this is the assumption used here, it is
      # acceptable to treat any BOS judging as the separate session the BOS
      # flights are and roll all judging points into one bucket.
      @judge_points = [ non_bos_sessions.select{|sess| sess.role == Judging::ROLE_JUDGE}.collect{|sess| sess.flight.judging_session.id}.uniq.length * 0.5,
                        PointAllocation.max_judge_points ].min unless non_bos_sessions.empty?

      # Determine steward points:
      #
      # Stewards earn 0.5 points per day with a maximum of 1.0 points per
      # competition, but no steward points are awarded if judge points
      # are also awarded.
      @steward_points = [ judging_sessions.select{|sess| sess.role == Judging::ROLE_STEWARD}.group_by{|sess| sess.flight.judging_session.date}.length * 0.5, 1.0 ].min unless @judge_points > 0.0 || judging_sessions.empty?
    end

    def before_validation
      [ first_name, middle_name, last_name, goes_by,
        address1, address2, address3, address4, city,
        postcode, email, phone, judge_number, comments ].each do |v|
        v.send('squish!') unless v.send('nil?')
      end
      judge_number.upcase! unless judge_number.nil?
      if !region_id.nil?
        self.region = Region.find(region_id)
        self.country = region.country
      elsif !country_id.nil?
        self.country = Country.find(country_id)
      end
    end

    def after_validation
      self.club = Club.find(club_id) if !club_id.nil? && club_id != Club.other.id
    end

    def before_create
      self.access_key = Digest::MD5.hexdigest((object_id + rand(255)).to_s)
    end

    def before_save
      # Discard a judge number for non-BJCP ranks
      self.judge_number = nil unless judge_rank && judge_rank.bjcp?
      
      # If club_name is specified, add it to the clubs table
      if club_id == Club.other.id && !club_name.blank?
        club_name.squish!

        # TODO: More sophisticated checking for similar, not just identical,
        # club names.

        # This doesn't quite do what we want since there's no way to check
        # for case-insenitive matches.
        #self.club = Club.find_or_create_by_name(club_name)

        record = Club.first(:conditions => [ 'LOWER(name) = ?', club_name.downcase ])
        record = Club.create(:name => club_name) if record.nil?
        self.club = record
      end
    end

    def validate_presence_of_name
      if first_name.blank? && last_name.blank?
        errors.add_to_base("A name is required")
      end
    end

    def validate_postal_address
      unless Controller.admin_view?
        # If any part of an address is specified, validate the full address
        unless address.blank? && city.blank? && region_id.nil? && postcode.blank?
          validate_street_address
          validate_city
          validate_region
          validate_postcode
        end
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
      unless Controller.admin_view?
        if email.blank? && phone.blank?
          errors.add_to_base("Either an email address or a phone number is required")
        end
      end
    end

    def validate_judge_number
      if !judge_rank.nil? && judge_rank.bjcp?
        if judge_number.blank?
          errors.add(:judge_number, I18n.t('activerecord.errors.messages.blank'))
        elsif /\A[A-G][0-9]{4}\z/.match(judge_number).nil?
          errors.add(:judge_number, I18n.t('activerecord.errors.messages.invalid'))
        end
      end
    end

    def ensure_only_one_organizer
      if Controller.admin_view?
        if organizer?
          existing_organizer = Judge.organizer
          errors.add_to_base("#{existing_organizer.name} is already defined as the competition organizer.") unless existing_organizer.nil? || existing_organizer.id == self.id
        end
      end
    end

    def validate_staff_points
      if Controller.admin_view?
        errors.add(:staff_points, "must not exceed #{available_staff_points}") unless staff_points <= available_staff_points
      end
    end

  private

    # Perform token substitution on the message
    def self.format_message(message, judge)
      # Prefer the name listed in the +goes_by+ column, unless it's blank.
      first_name = judge.goes_by
      first_name = judge.first_name if first_name.blank?

      message.
        gsub(JudgeInvite.tokens[:first_name].first, first_name).
        gsub(JudgeInvite.tokens[:last_name].first, judge.last_name).
        gsub(JudgeInvite.tokens[:full_name].first, judge.name)
    end

    def self.scope_for_target(target)
      scope = Judge.has_email
      case target
      when 'confirmed'
        scope.confirmed
      when 'unconfirmed'
        scope.unconfirmed
      end
      scope
    end

end
