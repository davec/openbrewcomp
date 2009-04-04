# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class RightTest < Test::Unit::TestCase

  def setup
    @existing_right = rights(:testright).name
  end

  def test_should_create_new_right
    assert_difference 'Right.count' do
      right = Right.new(:name => 'New Test',
                        :controller => 'test',
                        :action => 'create')
      assert right.save
    end
  end

  def test_should_not_create_with_duplicate_name
    assert_no_difference 'Right.count' do
      right = Right.new(:name => @existing_right,
                        :controller => 'test',
                        :action => '*')
      assert !right.save
      assert_equal 'already exists', right.errors.on(:name)
    end
  end

  def test_should_not_create_when_name_differs_only_in_case
    assert_no_difference 'Right.count' do
      right = Right.new(:name => @existing_right.downcase,
                        :controller => 'test',
                        :action => '*')
      assert !right.save
      assert_equal 'already exists', right.errors.on(:name)
    end
  end

  def test_should_not_create_when_name_differs_only_in_whitespace
    assert_no_difference 'Right.count' do
      right = Right.new(:name => " #{@existing_right.gsub(' ', '   ')} ",
                        :controller => 'test',
                        :action => '*')
      assert !right.save
      assert_equal 'already exists', right.errors.on(:name)
    end
  end

  def test_should_not_create_when_name_exceeds_max_length
    assert_no_difference 'Right.count' do
      right = Right.new(:name => "right#{'1234567890' * 6}",
                        :controller => 'test',
                        :action => '*')
      assert !right.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 60), right.errors.on(:name)
    end
  end

  def test_should_not_create_when_controller_name_exceeds_max_length
    assert_no_difference 'Right.count' do
      right = Right.new(:name => 'newright',
                        :controller => "controller#{'1234567890' * 4}",
                        :action => 'action')
      assert !right.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 40), right.errors.on(:controller)
    end
  end

  def test_should_not_create_when_action_name_exceeds_max_length
    assert_no_difference 'Right.count' do
      right = Right.new(:name => 'newright',
                        :controller => 'controller',
                        :action => "action#{'1234567890' * 4}")
      assert !right.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 40), right.errors.on(:action)
    end
  end

  def test_should_not_create_when_missing_name
    assert_no_difference 'Right.count' do
      right = Right.new(:description => 'A new right with no name',
                        :controller => 'test',
                        :action => '*')
      assert !right.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), right.errors.on(:name)
    end
  end

  def test_should_not_create_when_missing_controller
    assert_no_difference 'Right.count' do
      right = Right.new(:name => 'newright',
                        :description => 'A new right with no controller',
                        :action => '*')
      assert !right.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), right.errors.on(:controller)
    end
  end

  def test_should_not_create_when_missing_action
    assert_no_difference 'Right.count' do
      right = Right.new(:name => 'newright',
                        :description => 'A new right with no action',
                        :controller => 'test')
      assert !right.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), right.errors.on(:action)
    end
  end

end
