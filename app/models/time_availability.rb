# -*- coding: utf-8 -*-

class TimeAvailability < ActiveRecord::Base

  TIME_RANGE = 8..20.freeze

  belongs_to :judge

  validates_presence_of :start_time
  validates_presence_of :end_time

  validate :ensure_start_time_before_end_time

  def label
    "#{start_time.strftime('%A, %B %e, %l %p')} – #{end_time.strftime('%l %p')}"
  end

  protected

    def ensure_start_time_before_end_time
      unless start_time.nil? || end_time.nil?
        errors.add_to_base("Start time must be earlier than end time") unless start_time < end_time
      end
    end

end
