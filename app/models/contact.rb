# -*- coding: utf-8 -*-

class Contact < ActiveRecord::Base

  validates_presence_of :role, :name, :email
  validates_uniqueness_of :role

  def to_label
    role
  end

  def self.to_hash
    find(:all).inject({}) {|hash, record|
      hash[record.role] = { "name"  => record.name,
                            "email" => record.email }
      hash
    }
  end

  protected

    def validate
      errors.add_to_base("Email address #{I18n.t('activerecord.errors.messages.invalid')}") unless email.blank? || Email::validate_address(email)
    end

end
