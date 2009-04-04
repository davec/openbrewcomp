# -*- coding: utf-8 -*-

require 'digest/sha1'

class Password < ActiveRecord::Base

  belongs_to :user
  
  validates_presence_of :email, :user
  validates_format_of   :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => 'is not a valid email address'

  attr_accessor :email
  
  protected
  
    def before_create
      self.reset_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join )
      self.expires_at = 3.days.from_now
    end

end
