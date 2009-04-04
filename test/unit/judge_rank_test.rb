# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class JudgeRankTest < Test::Unit::TestCase

  def test_should_create_new_judge_rank
    assert_difference 'JudgeRank.count' do
      rank = JudgeRank.new(:description => 'New BJCP Rank',
                           :position => 99,
                           :bjcp => true)
      assert rank.save
    end
  end

  def test_should_not_create_when_description_exceeds_max_length
    assert_no_difference 'JudgeRank.count' do
      rank = JudgeRank.new(:description => 'An overly long description for a rank that does not exist',
                           :position => 99,
                           :bjcp => false)
      assert !rank.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 40), rank.errors.on(:description)
    end
  end

  def test_should_not_create_with_missing_description
    assert_no_difference 'JudgeRank.count' do
      rank = JudgeRank.new(:position => 99,
                           :bjcp => false)
      assert !rank.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), rank.errors.on(:description)
    end
  end

  def test_should_create_with_missing_position_and_append_to_list
    expected_position = JudgeRank.maximum(:position) + 1
    assert_difference 'JudgeRank.count' do
      rank = JudgeRank.new(:description => 'Nowhere to go',
                           :bjcp => false)
      assert rank.save
      assert_equal expected_position, rank.position
    end
  end

  def test_should_not_create_with_duplicate_description
    assert_no_difference 'JudgeRank.count' do
      rank = JudgeRank.new(:description => 'National',
                           :position => 99,
                           :bjcp => true)
      assert !rank.save
      assert_equal 'already exists', rank.errors.on(:description)
    end
  end

  def test_should_not_create_with_duplicate_position
    assert_no_difference 'JudgeRank.count' do
      rank = JudgeRank.new(:description => "I'm a Dup",
                           :position => 1,
                           :bjcp => false)
      assert !rank.save
      assert_equal 'already exists', rank.errors.on(:position)
    end
  end

  def test_should_not_create_with_non_numeric_position
    assert_no_difference 'JudgeRank.count' do
      rank = JudgeRank.new(:description => "I'm a Dup",
                           :position => 'first',
                           :bjcp => false)
      assert !rank.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), rank.errors.on(:position)
    end
  end

end
