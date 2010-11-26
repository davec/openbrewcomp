# -*- coding: utf-8 -*-

class Contact < ActiveRecord::Base

  validates_presence_of :role, :name, :email

  validates_length_of :role,  :maximum =>  40, :allow_blank => true
  validates_length_of :name,  :maximum =>  80, :allow_blank => true
  validates_length_of :email, :maximum => 100, :allow_blank => true

  validates_format_of :email, :allow_blank => true,
                              :with => Authentication.email_regex,
                              :message => Authentication.bad_email_message
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

  def self.roles
    find(:all).map(&:role)
  end

end
