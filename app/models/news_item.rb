# -*- coding: utf-8 -*-

require 'rdiscount'

class NewsItem < ActiveRecord::Base

  belongs_to :author, :foreign_key => 'author_id', :class_name => 'User'

  named_scope :recent, lambda {|count| { :limit => count,
                                         :order => 'COALESCE(updated_at, created_at) DESC' } }

  validates_presence_of :title, :description_raw

  attr_accessible :title, :description_raw, :description_encoded

  def description_encoded
    self.description_raw.nil? ? nil : NewsItem.encode(self.description_raw)
  end

  def last_edit
    updated_at || created_at
  end

  protected

    def before_save
      self.description_encoded = NewsItem.encode(self.description_raw)
    end

  private

    def self.encode(text)
      RDiscount.new(text).to_html
    end

end
