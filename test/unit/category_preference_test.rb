# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class CategoryPreferenceTest < ActiveSupport::TestCase

  def setup
    @judge_id = judges(:certified_judge).id
    @category_id = categories(:specialty).id
    @bos_category_id = categories(:bos).id
  end

  def test_new
    pref = CategoryPreference.new(:category_id => @category_id,
                                  :judge_id => @judge_id)
    assert pref.save
  end

  def test_non_public_category
    pref = CategoryPreference.new(:category_id => @bos_category_id,
                                  :judge_id => @judge_id)
    assert !pref.save
    assert_equal I18n.t('activerecord.errors.messages.invalid'), pref.errors.on(:category)
  end

end
