# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class RoundTest < ActiveSupport::TestCase

  def setup
    @existing_name = rounds(:first).name
    @existing_position = rounds(:second).position
    @new_name = 'Death Match'
    @new_position = Round.find(:first, :order => 'position DESC').position + 1
  end

  def test_should_create_new_round
    assert_difference 'Round.count' do
      round = Round.new(:name => @new_name,
                        :position => @new_position)
      assert round.save
    end
  end

  def test_should_not_create_with_duplicate_name
    assert_no_difference 'Round.count' do
      round = Round.new(:name => @existing_name,
                        :position => @new_position)
      assert !round.save
      assert_equal 'already exists', round.errors.on(:name)
    end
  end

  def test_should_not_create_when_name_differs_only_in_case
    assert_no_difference 'Round.count' do
      round = Round.new(:name => @existing_name.downcase,
                        :position => @new_position)
      assert !round.save
      assert_equal 'already exists', round.errors.on(:name)
    end
  end

  def test_should_not_create_when_name_differs_only_in_whitespace
    assert_no_difference 'Round.count' do
      round = Round.new(:name => " #{@existing_name.gsub(' ', '   ')} ",
                        :position => @new_position)
      assert !round.save
      assert_equal 'already exists', round.errors.on(:name)
    end
  end

  def test_should_not_create_with_duplicate_position
    assert_no_difference 'Round.count' do
      round = Round.new(:name => @new_name,
                        :position => @existing_position)
      assert !round.save
      assert_equal 'already exists', round.errors.on(:position)
    end
  end

  def test_should_not_create_with_non_numeric_position
    assert_no_difference 'Round.count' do
      round = Round.new(:name => @new_name,
                        :position => 'last')
      assert !round.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), round.errors.on(:position)
    end
  end

  def test_should_not_create_with_negative_position
    assert_no_difference 'Round.count' do
      round = Round.new(:name => @new_name,
                        :position => -1)
      assert !round.save
      assert_equal 'must be positive', round.errors.on(:position)
    end
  end

  def test_should_not_create_when_name_exceeds_max_length
    assert_no_difference 'Round.count' do
      round = Round.new(:name => "name#{'1234567890' * 2}")
      assert !round.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 20), round.errors.on(:name)
    end
  end

  def test_should_not_create_when_missing_name
    assert_no_difference 'Round.count' do
      round = Round.new(:position => @new_position)
      assert !round.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), round.errors.on(:name)
    end
  end

  def test_should_create_when_missing_position_and_append_to_list
    expected_position = Round.maximum(:position) + 1
    assert_difference 'Round.count' do
      round = Round.new(:name => @new_name)
      assert round.save
      assert_equal expected_position, round.position
    end
  end

end
