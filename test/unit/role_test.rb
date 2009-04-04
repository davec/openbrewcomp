# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class RoleTest < Test::Unit::TestCase

  def setup
    @existing_role = roles(:testrole).name
  end

  def test_should_create_new_role
    assert_difference 'Role.count' do
      role = Role.new(:name => 'New Role')
      assert role.save
    end
  end

  def test_should_not_create_with_duplicate_name
    assert_no_difference 'Role.count' do
      role = Role.new(:name => @existing_role)
      assert !role.save
      assert_equal 'already exists', role.errors.on(:name)
    end
  end

  def test_should_not_create_when_name_differs_only_in_case
    assert_no_difference 'Role.count' do
      role = Role.new(:name => @existing_role.downcase)
      assert !role.save
      assert_equal 'already exists', role.errors.on(:name)
    end
  end

  def test_should_not_create_when_name_differs_only_in_whitespace
    assert_no_difference 'Role.count' do
      role = Role.new(:name => " #{@existing_role.gsub(' ', '   ')} ")
      assert !role.save
      assert_equal 'already exists', role.errors.on(:name)
    end
  end

  def test_should_not_create_when_name_exceeds_max_length
    assert_no_difference 'Role.count' do
      role = Role.new(:name => "role#{'1234567890' * 6}")
      assert !role.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 60), role.errors.on(:name)
    end
  end

  def test_should_not_create_when_missing_name
    assert_no_difference 'Role.count' do
      role = Role.new(:description => 'A new role with no name')
      assert !role.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), role.errors.on(:name)
    end
  end

end
