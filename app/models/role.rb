# -*- coding: utf-8 -*-

class Role < ActiveRecord::Base

  has_and_belongs_to_many :users
  has_and_belongs_to_many :rights

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false,
                                 :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true
  validates_length_of :description, :maximum => 255, :allow_blank => true

  protected

    def before_validation
      name.squish! unless name.nil?
      description.squish! unless description.nil?
    end

end
