# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class CarbonationTest < Test::Unit::TestCase

  def setup
    @existing_description = carbonation(:still).description
    @existing_position = carbonation(:sparkling).position
    @new_description = 'Fizzy'
    @new_position = Carbonation.find(:first, :order => 'position DESC').position + 1
  end

  def test_should_save_with_new_description
    assert_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => @new_description,
                                    :position => @new_position)
      assert carbonation.save
    end
  end

  def test_should_not_save_with_duplicate_description
    assert_no_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => @existing_description,
                                    :position => @new_position)
      assert !carbonation.save
      assert_equal 'already exists', carbonation.errors.on(:description)
    end
  end

  def test_should_not_save_when_description_differs_only_in_case
    assert_no_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => @existing_description.downcase,
                                    :position => @new_position)
      assert !carbonation.save
      assert_equal 'already exists', carbonation.errors.on(:description)
    end
  end

  def test_should_not_save_when_description_differs_only_in_whitespace
    assert_no_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => " #{@existing_description.gsub(' ', '   ')} ",
                                    :position => @new_position)
      assert !carbonation.save
      assert_equal 'already exists', carbonation.errors.on(:description)
    end
  end

  def test_should_not_save_with_duplicate_position
    assert_no_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => @new_description,
                                    :position => @existing_position)
      assert !carbonation.save
      assert_equal 'already exists', carbonation.errors.on(:position)
    end
  end

  def test_should_not_save_with_non_numeric_position
    assert_no_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => @new_description,
                                    :position => 'last')
      assert !carbonation.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), carbonation.errors.on(:position)
    end
  end

  def test_should_not_save_with_negative_position
    assert_no_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => @new_description,
                                    :position => -1)
      assert !carbonation.save
      assert_equal 'must be positive', carbonation.errors.on(:position)
    end
  end

  def test_should_not_save_when_description_exceeds_max_length
    assert_no_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => "description#{'1234567890' * 4}",
                                    :position => @new_position)
      assert !carbonation.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 40), carbonation.errors.on(:description)
    end
  end

  def test_should_not_save_with_missing_description
    assert_no_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:position => @new_position)
      assert !carbonation.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), carbonation.errors.on(:description)
    end
  end

  def test_should_save_with_missing_position_and_append_to_list
    expected_position = Carbonation.maximum(:position) + 1
    assert_difference 'Carbonation.count' do
      carbonation = Carbonation.new(:description => @new_description)
      assert carbonation.save
      assert_equal expected_position, carbonation.position
    end
  end

end
