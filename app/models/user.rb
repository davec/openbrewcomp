# -*- coding: utf-8 -*-

require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  has_many :news_items, :foreign_key => 'author_id'
  has_many :entrants
  has_many :entries, :through => :entrants
  has_many :judges
  has_many :passwords, :dependent => :destroy
  has_and_belongs_to_many :roles

  named_scope :admins, :conditions => { :is_admin => true }

  validates_presence_of   :login, :if => :not_using_openid?
  validates_length_of     :login, :if => :not_using_openid?,
                                  :within => 3..40
  validates_format_of     :login, :if => :not_using_openid?,
                                  :with => Authentication.login_regex,
                                  :message => Authentication.bad_login_message
  validates_uniqueness_of :login, :if => :not_using_openid?,
                                  :scope => 'identity_url',
                                  :case_sensitive => false

  validates_length_of :name, :if => :not_using_openid?,
                             :allow_blank => true,
                             :maximum => 80
  validates_format_of :name, :if => :not_using_openid?,
                             :allow_blank => true,
                             :with => Authentication.name_regex,
                             :message => Authentication.bad_name_message

  validates_length_of     :email, :if => :not_using_openid?,
                                  :allow_blank => true,
                                  :maximum => 100
  validates_format_of     :email, :if => :not_using_openid?,
                                  :allow_blank => true,
                                  :with => Authentication.email_regex,
                                  :message => Authentication.bad_email_message
  validates_uniqueness_of :email, :if => :not_using_openid?,
                                  :allow_blank => true,
                                  :scope => 'identity_url',
                                  :case_sensitive => false,
                                  :message => 'is already registered'
  validates_uniqueness_of :identity_url, :unless => :not_using_openid?

  validate :normalize_identity_url, :unless => :not_using_openid?
  validate :ensure_new_password_and_old_password_are_different, :if => :not_using_openid?
  validate :ensure_password_and_login_are_different, :if => :not_using_openid?

  attr_accessor :current_password

  # The following attributes are the only ones allowed to be set via bulk assignment
  attr_accessible :login, :password, :password_confirmation, :current_password, :name, :email, :identity_url

  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    user = self.find(:first, :conditions => { :login => login.downcase, :identity_url => nil })
    user && user.authenticated?(password) ? user : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  # Check if a user has a role.
  def has_role?(role)
    @_list ||= self.roles.map(&:name)
    @_list.include?(APP_CONFIG[:admin_name]) || @_list.include?(role.to_s)
  end
  
  # Not using open id
  def not_using_openid?
    identity_url.blank?
  end
  
  # Overwrite password_required for open id
  def password_required?
    new_record? \
      ? !is_anonymous? && not_using_openid? && (crypted_password.blank? || !password.blank?) \
      : !password.blank?
  end

  # Save the last logon time to the database without updating updated_at.
  # Adapted from http://www.railsweenie.com/forums/1/topics/688
  def last_logon_at=(time)
    class << self
      def record_timestamps; false; end
    end
    self[:last_logon_at] = time
    save!
    class << self
      remove_method :record_timestamps
    end
  end

  def to_label
    login
  end

  def display_name
    is_anonymous ? 'Anonymous Serf' : (name.blank? ? login : name)
  end

  def self.admin_id
    User.find_by_login(APP_CONFIG[:admin_name]).id
  end

  def self.anonymous_user
    user = nil
    1.upto(10) do  # So we don't get stuck in an unlikely endless loop
      begin
        user = User.new(:login => User.anonymous_username,
                        :full_name => "Anonymous@#{Time.now.utc.to_s(:db).sub(' ','T')}Z")
        user.is_anonymous = true
        user.save!
        break
      rescue ActiveRecord::RecordInvalid
        # Loop back and try again
      end
    end
    user
  end

  def authorized_for_update?
    # The admin user can update all accounts
    return true if current_user.id == User.admin_id
    # No other users can update the admin account
    return false if APP_CONFIG[:admin_name] == login
    # All other users can update their own accounts
    return true if current_user.id == id
    # Other admins can update accounts if they have privs to do so
    current_user.roles.detect{|role|
      role.rights.detect{|right|
        right.controller == 'users' && right.action == 'update'
      }
    }
  end

  def authorized_for_destroy?
    # Neither the admin account nor the current user account can be destroyed
    self.login != APP_CONFIG[:admin_name] && self.id != current_user.id
  end

  protected

    def normalize_identity_url
      self.identity_url = OpenIdAuthentication.normalize_url(identity_url) unless not_using_openid?
    rescue URI::InvalidURIError
      errors.add_to_base("Invalid OpenID URL")
    end

    def before_save
      return if not_using_openid?
      # Truncate OpenID SReg values if necessary
      self.login = login[0,column_for_attribute(:login).limit]
      self.email = email[0,column_for_attribute(:email).limit]
      self.name = name[0,column_for_attribute(:name).limit]
    end

    # Automatically enable a non-anonymous account when it is created.
    def before_create
      self.enabled = !self.is_anonymous?
      # Return true, otherwise the value of self.enabled is returned which
      # is not acceptable if it's set to false.
      true
    end

    # Don't allow the admin account to be renamed
    def before_update
      raise "The admin account cannot be renamed." if User.find(id).login == APP_CONFIG[:admin_name] and self.login != APP_CONFIG[:admin_name]
    end

    # Don't allow the admin account to be deleted
    def before_destroy
      raise "The admin account cannot be deleted." if self.login == APP_CONFIG[:admin_name]
    end

    def before_validation
      login.downcase! if login
    end

    def ensure_new_password_and_old_password_are_different
      errors.add(:password, "password is the same as the current password") if password_required? && password == current_password
    end

    def ensure_password_and_login_are_different
      if password && login
        errors.add(:password, "cannot be the same as your login name") if password_required? && password.downcase == login
        errors.add(:password, "cannot be the reverse of your login name") if password_required? && password.downcase == login.reverse
      end
    end

  private

    def self.anonymous_username
      name = `uuidgen`.strip.gsub('-','')
      unless $?.success?
        name = Time.now.to_i.to_s(16) + rand(0x7fffffff).to_s(16)
      end
      "__anon__#{name.downcase}"
    end

end
