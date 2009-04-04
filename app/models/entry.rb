# -*- coding: utf-8 -*-

class Entry < ActiveRecord::Base
  include ActionView::Helpers::TextHelper  # For use in error messages
  include ExportHelper

  belongs_to :entrant
  belongs_to :style
  belongs_to :user
  belongs_to :carbonation
  belongs_to :strength
  belongs_to :sweetness
  has_and_belongs_to_many :flights
  has_many :scores, :dependent => :destroy

  named_scope :checked_in, :conditions => 'bottle_code IS NOT NULL'

  #validates_presence_of :style_id
  #validates_presence_of :base_style_id,
  #                      :if => lambda { |e| !e.style.nil? && e.style.id == Style.first_time.id }

  validates_length_of :name, :maximum => 80, :allow_blank => true

  validates_uniqueness_of :bottle_code, :allow_nil => true,
                          :message => "already exists"
  validates_numericality_of :bottle_code, :only_integer => true, :allow_blank => true

  attr_accessor :base_style
  attr_accessor :classic_style, :classic_style_id

  attr_reader :warning

  def category
    style.nil? ? '' : style.category_and_name
  end

  def base_category
    base_style_id.nil? ? '' : Style.find(base_style_id).category_and_name
  end

  def registration_code
    # The registration code is based on the current year (year * 10000 + id)
    # and produces codes such as 20070666. This works as long as the entry ID
    # is less than 10000, which is only likely to not be true if data from
    # previous years is not cleared out before beginning a new competition,
    # or a malicious user enters a lot of bogus entries. In that case, the
    # leading year will just roll over and we'll see registration codes like
    # 20080420 even in 2007.
    #
    # An alternative approach is to use the year in which the competition is
    # held (CompetitionData.instance.competition_date.year), but this requires
    # that the competition date be set properly which, for whatever reason,
    # may not happen.
    #
    # What we definitely do not want to do is use an opaque identifier such
    # as a UUID or hash value since such values are very unfriendly to anyone
    # who needs to search for them. Does anyone really want to search for
    # a registration code like BDE17432-CA0B-479C-B5F4-D2201DF725CF or
    # 47daf813ad58332d1e7704a8a90fae9e01745a10 when assigning bottle codes?
    # Sure, such a scheme could work if the printed bottle labels included a
    # bar code that could be scanned during entry processing, but we're (1)
    # not at that stage and (2) it puts a heavier load on the database having
    # to index such values instead of simple integers.

    created_at.nil? ? '' : created_at.year * 10000 + id
  end

  def checked_in?
    !bottle_code.nil?
  end

  def to_label
    send(Controller.label || :registration_code)
  end

  def avg_score
    # FIXME: This grabs all scores for an entry, which isn't what we want if
    # scores were recorded for both first- and second-round judging.
    scores.empty? ? 'N/A' : scores.inject(0.0){|sum,s| sum + s.score}/scores.length
  end

  # Define a method to be used for sorting categories
  def category_sort_value
    v = style.bjcp_category * 1000
    v += style.bjcp_subcategory[0] unless style.bjcp_subcategory.empty?
    v
  end

  # Define a method to be used for sorting places
  def place_sort_value
    place.nil? ? 99 : place
  end

  # Define a method to be used for sorting bottle codes
  def bottle_code_sort_value
    bottle_code.nil? ? 2147483647 : bottle_code
  end

  # Define a method to be used for sorting average scores
  def avg_score_sort_value
    avg_score.to_s
  end

  # Export the table
  def self.export(format)
    case format
    when 'csv'
      to_csv(:columns => [ 'bottle_code', 'registration_code', 'entrant_id', 'name', 'style_id', 'base_style_id', 'carbonation_id', 'strength_id', 'sweetness_id', 'odd_bottle', 'style_info', 'competition_notes' ])
    when 'yml', 'yaml'
      to_yaml
    else
      raise ArgumentError, "Invalid format: #{format}"
    end
  end

  def authorized_for?(action)
    # NOTE: action[:action] is really the link's crud_type
    # (see active_scaffold/data_structures/action_columns.rb)
    # as configured for the action_link in the controller.
    if action[:action] == 'print'
      self.bottle_code.nil?
    else
      super
    end
  end

  def authorized_for_update?
    # Users must be logged in to update an entry
    return false unless current_user
    # and logged-in users can generally update entries
    return true unless existing_record_check?
    # and users with update rights can update entries in the admin interface
    return current_user.roles.detect{|role|
             role.rights.detect{|right|
               right.controller == 'entries' && right.action == 'update'
             }
           } if Controller.admin_view?
    # unless a bottle code has been assigned.
    self.bottle_code.nil?
  end

  def authorized_for_destroy?
    # Users must be logged in to delete an entry
    return false unless current_user
    # and logged-in users can generally delete entries
    return true unless existing_record_check?
    # and users with delete rights can delete entries in the admin interface
    return current_user.roles.detect{|role|
             role.rights.detect{|right|
               right.controller == 'entries' && right.action == 'delete'
             }
           } if Controller.admin_view?
    # unless a bottle code has been assigned.
    self.bottle_code.nil?
  end

  protected

    def before_validation
      unless base_style.is_a?(Style) && base_style[:id] == base_style_id
        if base_style.is_a?(Hash)
          # normal use
          self.base_style = (base_style.nil? || base_style[:id].blank?) ? nil : Style.find(base_style[:id])
          self.base_style_id = base_style[:id] unless base_style.nil?
        elsif base_style_id.to_i > 0
          # unit test and flight update
          self.base_style = Style.find(base_style_id.to_i)
          self.base_style_id = base_style[:id] unless base_style.nil?
        end
      end
      unless classic_style.is_a?(Style) && classic_style[:id] == classic_style_id
        if classic_style.is_a?(Hash)
          # normal use
          self.classic_style = (classic_style.nil? || classic_style[:id].blank?) ? nil : Style.find(classic_style[:id])
          self.classic_style_id = classic_style[:id] unless classic_style.nil?
        elsif classic_style_id.to_i > 0
          # unit test and flight update
          self.classic_style = Style.find(classic_style_id.to_i)
          self.classic_style_id = classic_style[:id] unless classic_style.nil?
        end
      end
    end

    def after_validation
      return unless style

      # Reset any irrelevant columns (to keep bogus data out of the database)
      carbonation = nil unless style.require_carbonation
      strength = nil unless style.require_strength
      sweetness = nil unless style.require_sweetness
      if style[:id] != Style.first_time.id && style.optional_classic_style?
        unless classic_style.nil? || base_style == classic_style
          # HACK: classic_style, as used for official BJCP categories, must be
          # translated into base_style.  Only the First-Time Entrant category
          # uses base_style in the form, but they're both stored in the database
          # as base_style.
          self.base_style = classic_style
          self.base_style_id = classic_style_id
        end
      else
        self.base_style = nil
      end
    end

    def before_save
      name.squish! unless name.nil?
      style_info.squish! unless style_info.nil?
      competition_notes.squish! unless competition_notes.nil?
      self.place = nil unless place.nil? || place > 0
      self.bos_place = nil unless bos_place.nil? || bos_place > 0
    end

    def after_save
      # Notify the user if the number of entries in an award category exceeds
      # the limit specified in the rules.
      if Controller.admin_view?
        # Check only entries with assigned bottle labels in admin mode
        category_entries = entrant.entries.find(:all,
                                                :conditions => [ 'bottle_code is not null and style_id in (?)', style.award.styles.map(&:id) ],
                                                :order => 'bottle_code ASC')
      else
        # Check all entries in non-admin mode
        category_entries = entrant.entries.find(:all,
                                                :conditions => { :style_id => style.award.styles.map(&:id) },
                                                :order => 'id ASC')
      end
      @warning = "Warning: #{excess_error_message(category_entries, style, false)}" if Award::MAX_ENTRIES && category_entries.length > Award::MAX_ENTRIES
    end

    def after_find
      if base_style_id
        # The First-Time Entrant category references base_style (which includes
        # all styles in BJCP categories 1 - 28) while all other categories that
        # specify a base style reference classic_style (which only includes the
        # "classic" styles in BJCP categories 1 - 19).
        if style_id == Style.first_time.id
          self.base_style = Style.find(base_style_id)
        else
          self.classic_style = Style.find(base_style_id)
        end
      end
    end

    def validate
      if style
        if style[:id] == Style.first_time.id
          # First-time entrant requires a base style to be specified
          if base_style && base_style.bjcp_category <= 28
            validate_style(Style.find(base_style_id))
          elsif base_style && base_style.bjcp_category > 28
            errors.add(:base_style, I18n.t('activerecord.errors.messages.invalid'))
          else
            errors.add_to_base('A base style must be specified')
          end
        else
          validate_style(style)
        end
      else
        errors.add_to_base('A style must be specified')
      end
    end

    def odd_bottle_authorized?
      Controller.admin_view?
    end

    def bottle_code_authorized?
      Controller.admin_view?
    end

    def competition_notes_authorized?
      Controller.admin_view?
    end

    def entrant_authorized?
      Controller.admin_view? && !Controller.nested_view?
    end

    def checked_in_authorized?
      !Controller.admin_view?
    end

  private

    def validate_style(style)
      if style.style_info.required?
        errors.add_to_base('Style information must be specified') if style_info.blank?
      end

      if style.optional_classic_style && classic_style_id
        classic_style = Style.find(classic_style_id)
        errors.add(:classic_style, I18n.t('activerecord.errors.messages.invalid')) if classic_style.category.to_i >= 20
      end

      if style.require_carbonation || style.require_strength || style.require_sweetness
        # HACK: Adding the error messages to the individual properties causes
        # layout problems with the radio buttons, so we add the error messages
        # to the base error message array instead.
        errors.add_to_base('The sweetness level must be specified') if style.require_sweetness && sweetness.blank?
        errors.add_to_base('The carbonation level must be specified') if style.require_carbonation && carbonation.blank?
        errors.add_to_base('The strength level must be specified') if style.require_strength && strength.blank?

        if sweetness_id
          # NOTE: We should not need these checks in normal circumstances because
          # the sweetness radio buttons are supposed to be hidden in the UI for
          # the category 24 meads.
          case style.category
          when '24A'  # Dry mead
            errors.add(:sweetness, 'must be dry') if /^dry/i.match(sweetness.description).nil?
          when '24B'  # Semi-sweet mead
            errors.add(:sweetness, 'must be semi-sweet') if /^semi/i.match(sweetness.description).nil?
          when '24C'  # Sweet mead
            errors.add(:sweetness, 'must be sweet') if /^sweet/i.match(sweetness.description).nil?
          end
        end
      end
    end

    def excess_error_message(category_entries, style, html_formatting = true)
      msg = entrant.name
      msg << " has #{pluralize(category_entries.length, 'entry')} (#{category_entries.collect{|e| Controller.admin_view? ? e.bottle_code : e.registration_code}.to_sentence(:skip_last_comma => true)}) in the #{style.award.name} category."
      msg << (html_formatting ? "<br />" : "\n\n")
      msg << "A maximum of #{pluralize(Award::MAX_ENTRIES, 'entry')} per award category is allowed."
      msg
    end

end
