# -*- coding: utf-8 -*-

require 'bluecloth'

class NewsItem < ActiveRecord::Base

  belongs_to :author, :foreign_key => 'author_id', :class_name => 'User'

  validates_presence_of :title, :description_raw

  attr_accessible :title, :description_raw, :description_encoded

  def description_encoded
    self.description_raw.nil? ? nil : NewsItem.encode(self.description_raw)
  end

  def last_edit
    updated_at.nil? ? created_at : updated_at
  end

  protected

    def before_save
      self.description_encoded = NewsItem.encode(self.description_raw)
    end

  private

    def self.encode(text)
      BlueCloth.new(text).to_html
    end

end
