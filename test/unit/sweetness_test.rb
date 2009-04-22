# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class SweetnessTest < ActiveSupport::TestCase

  def setup
    @existing_description = sweetness(:sweet).description
    @existing_position = sweetness(:dry).position
    @new_description = 'Syrupy Sweet'
    @new_position = Sweetness.find(:first, :order => 'position DESC').position + 1
  end

  def test_should_save_with_new_description
    assert_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => @new_description,
                                :position => @new_position)
      assert sweetness.save
    end
  end

  def test_should_not_save_with_duplicate_description
    assert_no_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => @existing_description,
                                :position => @new_position)
      assert !sweetness.save
      assert_equal 'already exists', sweetness.errors.on(:description)
    end
  end

  def test_should_not_save_when_description_differs_only_in_case
    assert_no_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => @existing_description.downcase,
                                :position => @new_position)
      assert !sweetness.save
      assert_equal 'already exists', sweetness.errors.on(:description)
    end
  end

  def test_should_not_save_when_description_differs_only_in_whitespace
    assert_no_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => " #{@existing_description.gsub(' ', '   ')} ",
                                :position => @new_position)
      assert !sweetness.save
      assert_equal 'already exists', sweetness.errors.on(:description)
    end
  end

  def test_should_not_save_with_duplicate_position
    assert_no_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => @new_description,
                                :position => @existing_position)
      assert !sweetness.save
      assert_equal 'already exists', sweetness.errors.on(:position)
    end
  end

  def test_should_not_save_with_non_numeric_position
    assert_no_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => @new_description,
                                :position => 'last')
      assert !sweetness.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), sweetness.errors.on(:position)
    end
  end

  def test_should_not_save_with_negative_position
    assert_no_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => @new_description,
                                :position => -1)
      assert !sweetness.save
      assert_equal 'must be positive', sweetness.errors.on(:position)
    end
  end

  def test_should_not_save_when_description_exceeds_max_length
    assert_no_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => "description#{'1234567890' * 4}",
                                :position => @new_position)
      assert !sweetness.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 40), sweetness.errors.on(:description)
    end
  end

  def test_should_not_save_with_missing_description
    assert_no_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:position => @new_position)
      assert !sweetness.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), sweetness.errors.on(:description)
    end
  end

  def test_should_save_with_missing_position_and_append_to_list
    expected_position = Sweetness.maximum(:position) + 1
    assert_difference 'Sweetness.count' do
      sweetness = Sweetness.new(:description => @new_description)
      assert sweetness.save
      assert_equal expected_position, sweetness.position
    end
  end

end
