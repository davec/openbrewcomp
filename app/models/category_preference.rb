# -*- coding: utf-8 -*-

class CategoryPreference < ActiveRecord::Base

  MAX_PREFERENCES = 3

  belongs_to :judge
  belongs_to :category

  validates_presence_of :category

  validate :ensure_category_is_public

  def label
    category.name_with_index
  end

  private

    def ensure_category_is_public
      errors.add(:category, I18n.t('activerecord.errors.messages.invalid')) unless category.nil? or category.is_public?
    end

end
