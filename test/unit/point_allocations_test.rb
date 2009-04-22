# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class PointAllocationsTest < ActiveSupport::TestCase

  def test_should_create_new_record
    assert_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 1000,
                                             :max_entries => 1099,
                                             :organizer => 6.0,
                                             :staff => 13.0,
                                             :judge => 5.5)
      assert point_allocation.save
    end
  end

  def test_should_not_create_when_min_greater_than_max
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 1199,
                                             :max_entries => 1100,
                                             :organizer => 6.0,
                                             :staff => 13.0,
                                             :judge => 5.5)
      assert !point_allocation.save
      assert_equal 'The minimum entry count must be less than the maximum entry count', point_allocation.errors.on(:base)
    end
  end

  def test_should_not_create_duplicates
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 1,
                                             :max_entries => 99,
                                             :organizer => 2.0,
                                             :staff => 2.0,
                                             :judge => 2.0)
      assert !point_allocation.save
      assert_equal 'already exists', point_allocation.errors.on(:min_entries)
      assert_equal 'already exists', point_allocation.errors.on(:max_entries)
    end
  end

  def test_should_not_create_with_non_integer_entry_values
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 1200.1,
                                             :max_entries => 1299.0,
                                             :organizer => 5.0,
                                             :staff => 15.0,
                                             :judge => 5.5)
      assert !point_allocation.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), point_allocation.errors.on(:min_entries)
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), point_allocation.errors.on(:max_entries)
    end
  end

  def test_should_not_create_with_non_numeric_entry_values
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 'lots',
                                             :max_entries => 'lots more',
                                             :organizer => 5.0,
                                             :staff => 15.0,
                                             :judge => 5.5)
      assert !point_allocation.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), point_allocation.errors.on(:min_entries)
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), point_allocation.errors.on(:max_entries)
    end
  end

  def test_should_not_create_with_negative_entry_values
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => -9,
                                             :max_entries => -1,
                                             :organizer => 1.0,
                                             :staff => 1.0,
                                             :judge => 1.0)
      assert !point_allocation.save
      assert_equal 'must be positive', point_allocation.errors.on(:min_entries)
      assert_equal 'must be positive', point_allocation.errors.on(:max_entries)
    end
  end

  def test_should_not_create_when_points_are_not_in_half_point_increments
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 1100,
                                             :max_entries => 1199,
                                             :organizer => 6.1,
                                             :staff => 13.2,
                                             :judge => 5.3)
      assert !point_allocation.save
      assert_equal PointAllocation::FORMAT_ERROR, point_allocation.errors.on(:organizer)
      assert_equal PointAllocation::FORMAT_ERROR, point_allocation.errors.on(:staff)
      assert_equal PointAllocation::FORMAT_ERROR, point_allocation.errors.on(:judge)
    end
  end

  def test_should_not_create_when_points_are_not_decimal_values
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 1100,
                                             :max_entries => 1199,
                                             :organizer => 'six',
                                             :staff => 'thirteen',
                                             :judge => 'five')
      assert !point_allocation.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), point_allocation.errors.on(:organizer)
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), point_allocation.errors.on(:staff)
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), point_allocation.errors.on(:judge)
    end
  end

  def test_should_not_create_when_point_values_are_negative
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 1100,
                                             :max_entries => 1199,
                                             :organizer => -6.0,
                                             :staff => -13.2,
                                             :judge => -5.0)
      assert !point_allocation.save
      assert_equal PointAllocation::FORMAT_ERROR, point_allocation.errors.on(:organizer)
      assert_equal PointAllocation::FORMAT_ERROR, point_allocation.errors.on(:staff)
      assert_equal PointAllocation::FORMAT_ERROR, point_allocation.errors.on(:judge)
    end
  end

  def test_should_not_create_with_missing_elements
    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new
      assert !point_allocation.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), point_allocation.errors.on(:min_entries)
      assert_equal I18n.t('activerecord.errors.messages.blank'), point_allocation.errors.on(:max_entries)
      assert_equal I18n.t('activerecord.errors.messages.blank'), point_allocation.errors.on(:organizer)
      assert_equal I18n.t('activerecord.errors.messages.blank'), point_allocation.errors.on(:staff)
      assert_equal I18n.t('activerecord.errors.messages.blank'), point_allocation.errors.on(:judge)
    end

    assert_no_difference 'PointAllocation.count' do
      point_allocation = PointAllocation.new(:min_entries => 1100,
                                             :max_entries => 1199)
      assert !point_allocation.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), point_allocation.errors.on(:organizer)
      assert_equal I18n.t('activerecord.errors.messages.blank'), point_allocation.errors.on(:staff)
      assert_equal I18n.t('activerecord.errors.messages.blank'), point_allocation.errors.on(:judge)
    end
  end

end
