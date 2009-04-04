# -*- coding: utf-8 -*-

class Score < ActiveRecord::Base
  belongs_to :entry
  belongs_to :judge
  belongs_to :flight

  SCORE_RANGE = (0.0..50.0)

  # TODO: Enable validation of scores.  For now, invalid scores hose the
  # flight entry panel -- needs further investigation.

  #validates_inclusion_of :score, :allow_blank => true,
  #                       :in => SCORE_RANGE,
  #                       :message => "must be between #{SCORE_RANGE.begin} and #{SCORE_RANGE.end}"

  validates_associated :entry
  validates_associated :judge
  validates_associated :flight

  def to_label
    score.nil? ? 'N/A' : score
  end

end
