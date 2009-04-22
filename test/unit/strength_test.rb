# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class StrengthTest < ActiveSupport::TestCase

  def setup
    @existing_description = strength(:standard).description
    @existing_position = strength(:light).position
    @new_description = "Honkin' Huge"
    @new_position = Strength.find(:first, :order => 'position DESC').position + 1
  end

  def test_should_save_with_new_description
    assert_difference 'Strength.count' do
      strength = Strength.new(:description => @new_description,
                              :position => @new_position)
      assert strength.save
    end
  end

  def test_should_not_save_with_duplicate_description
    assert_no_difference 'Strength.count' do
      strength = Strength.new(:description => @existing_description,
                              :position => @new_position)
      assert !strength.save
      assert_equal 'already exists', strength.errors.on(:description)
    end
  end

  def test_should_not_save_when_description_differs_only_in_case
    assert_no_difference 'Strength.count' do
      strength = Strength.new(:description => @existing_description.downcase,
                              :position => @new_position)
      assert !strength.save
      assert_equal 'already exists', strength.errors.on(:description)
    end
  end

  def test_should_not_save_when_description_differs_only_in_whitespace
    assert_no_difference 'Strength.count' do
      strength = Strength.new(:description => " #{@existing_description.gsub(' ', '   ')} ",
                              :position => @new_position)
      assert !strength.save
      assert_equal 'already exists', strength.errors.on(:description)
    end
  end

  def test_should_not_save_with_duplicate_position
    assert_no_difference 'Strength.count' do
      strength = Strength.new(:description => @new_description,
                              :position => @existing_position)
      assert !strength.save
      assert_equal 'already exists', strength.errors.on(:position)
    end
  end

  def test_should_not_save_with_non_numeric_position
    assert_no_difference 'Strength.count' do
      strength = Strength.new(:description => @new_description,
                              :position => 'last')
      assert !strength.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), strength.errors.on(:position)
    end
  end

  def test_should_not_save_with_negative_position
    assert_no_difference 'Strength.count' do
      strength = Strength.new(:description => @new_description,
                              :position => -1)
      assert !strength.save
      assert_equal 'must be positive', strength.errors.on(:position)
    end
  end

  def test_should_not_save_when_description_exceeds_max_length
    assert_no_difference 'Strength.count' do
      strength = Strength.new(:description => "description#{'1234567890' * 4}",
                              :position => @new_position)
      assert !strength.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 40), strength.errors.on(:description)
    end
  end

  def test_should_not_save_with_missing_description
    assert_no_difference 'Strength.count' do
      strength = Strength.new(:position => @new_position)
      assert !strength.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), strength.errors.on(:description)
    end
  end

  def test_should_save_with_missing_position_and_append_to_list
    expected_position = Strength.maximum(:position)+1
    assert_difference 'Strength.count' do
      strength = Strength.new(:description => @new_description)
      assert strength.save
      assert_equal expected_position, strength.position
    end
  end

end
