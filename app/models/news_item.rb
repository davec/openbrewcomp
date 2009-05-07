# -*- coding: utf-8 -*-

require 'rdiscount'

class NewsItem < ActiveRecord::Base

  belongs_to :author, :foreign_key => 'author_id', :class_name => 'User'

  named_scope :recent, lambda {|count| { :limit => count,
                                         :order => 'COALESCE(updated_at, created_at) DESC' } }

  validates_presence_of :title, :description_raw

  attr_accessible :title, :description_raw, :description_encoded

  def last_edit
    updated_at || created_at
  end

  protected

    def before_save
      self.description_encoded = NewsItem.encode(description_raw)
    end

  private

    # HACK: This is here only because the test fixtures need access to it.
    def self.encode(text)
      RDiscount.new(text).to_html
    end

end
