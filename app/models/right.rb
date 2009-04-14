# -*- coding: utf-8 -*-

class Right < ActiveRecord::Base

  has_and_belongs_to_many :roles

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false,
                                 :message => 'already exists'
  validates_length_of :name, :maximum => 60, :allow_blank => true

  validates_length_of :description, :maximum => 255, :allow_blank => true

  validates_presence_of :controller
  validates_length_of :controller, :maximum => 40, :allow_blank => true

  validates_presence_of :action
  validates_length_of :action, :maximum => 40, :allow_blank => true

  protected

    def before_validation
      name.squish! unless name.nil?
      description.squish! unless description.nil?
      controller.strip! unless controller.nil?
      action.strip! unless action.nil?
    end

end
