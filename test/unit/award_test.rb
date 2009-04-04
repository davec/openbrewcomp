# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class AwardTest < Test::Unit::TestCase

  def setup
    @existing_category = categories(:specialty)
    @existing_award = awards(:SPC)
  end

  def test_should_add_new_award
    assert_difference 'Award.count' do
      award = Award.new(:name => 'New Award',
                        :category_id => @existing_category.id,
                        :position => @existing_category.awards.length + 1)
      assert award.save
    end
  end

  def test_should_not_add_duplicate_award
    assert_no_difference 'Award.count' do
      award = Award.new(:name => @existing_award.name,
                        :category_id => @existing_category.id,
                        :position => 1)
      assert !award.save
      assert_equal 'already exists', award.errors.on(:name)
    end
  end

  def test_should_not_add_when_name_differs_only_in_case
    assert_no_difference 'Award.count' do
      award = Award.new(:name => @existing_award.name.downcase,
                        :category_id => @existing_category.id,
                        :position => 1)
      assert !award.save
      assert_equal 'already exists', award.errors.on(:name)
    end
  end

  def test_should_not_add_when_name_differs_only_in_whitespace
    assert_no_difference 'Award.count' do
      award = Award.new(:name => " #{@existing_award.name.gsub(' ', '   ')} ",
                        :category_id => @existing_category.id,
                        :position => 1)
      assert !award.save
      assert_equal 'already exists', award.errors.on(:name)
    end
  end

  def test_should_not_add_with_missing_name
    assert_no_difference 'Award.count' do
      award = Award.new(:category_id => @existing_category.id,
                        :position => @existing_category.awards.length + 1)
      assert !award.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), award.errors.on(:name)
    end
  end

  def test_should_not_add_when_name_exceeds_max_length
    assert_no_difference 'Award.count' do
      award = Award.new(:name => "Award#{'1234567890' * 6}",
                        :category_id => @existing_category.id,
                        :position => @existing_category.awards.length + 1)
      assert !award.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 60), award.errors.on(:name)
    end
  end

  def test_should_not_add_duplicate_position_in_category
    assert_no_difference 'Award.count' do
      award = Award.new(:name => 'New Award',
                        :category_id => @existing_category.id,
                        :position => 1)
      assert !award.save
      assert_equal 'already exists', award.errors.on(:position)
    end
  end

  def test_should_not_add_non_numeric_position
    assert_no_difference 'Award.count' do
      award = Award.new(:name => 'New Award',
                        :category_id => @existing_category.id,
                        :position => 'last')
      assert !award.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), award.errors.on(:position)
    end
  end

end
