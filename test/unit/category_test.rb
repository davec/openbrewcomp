# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class CategoryTest < Test::Unit::TestCase

  def setup
    @good_category_id = categories(:specialty).id
    @existing_category_name = categories(:specialty).name
    @existing_position = Category.find(:first, :order => 'position DESC').position
    @new_position = @existing_position + 1
  end

  def test_should_create_new_category
    assert_difference 'Category.count' do
      category = Category.new(:name => 'New Category',
                              :position => @new_position)
      assert category.save
    end
  end

  def test_should_not_add_duplicate_category_name
    assert_no_difference 'Category.count' do
      category = Category.new(:name => @existing_category_name,
                              :position => @new_position)
      assert !category.save
      assert_equal 'already exists', category.errors.on(:name)
    end
  end

  def test_should_not_add_duplicate_category_position
    assert_no_difference 'Category.count' do
      category = Category.new(:name => 'New Category',
                              :position => @existing_position)
      assert !category.save
      assert_equal 'already exists', category.errors.on(:position)
    end
  end

  def test_should_not_add_category_when_name_differs_only_in_case
    assert_no_difference 'Category.count' do
      category = Category.new(:name => @existing_category_name.downcase,
                              :position => @new_position)
      assert !category.save
      assert_equal 'already exists', category.errors.on(:name)
    end
  end

  def test_should_not_add_category_when_name_differs_only_in_whitespace
    assert_no_difference 'Category.count' do
      category = Category.new(:name => " #{@existing_category_name.gsub(' ', '   ')} ",
                              :position => @new_position)
      assert !category.save
      assert_equal 'already exists', category.errors.on(:name)
    end
  end

  def test_should_not_add_category_when_name_exceeds_max_length
    assert_no_difference 'Category.count' do
      category = Category.new(:name => "category#{'1234567890' * 6}",
                              :position => @new_position)
      assert !category.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 60), category.errors.on(:name)
    end
  end

  def test_should_not_add_when_missing_name
    assert_no_difference 'Category.count' do
      category = Category.new(:position => @new_position)
      assert !category.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), category.errors.on(:name)
    end
  end

  def test_should_not_add_when_missing_position
    assert_no_difference 'Category.count' do
      category = Category.new(:name => 'New Category')
      assert !category.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), category.errors.on(:position)
    end
  end

  def test_should_not_add_when_position_is_out_of_range
    assert_no_difference 'Category.count' do
      category = Category.new(:name => 'New Category',
                              :position => Category::CATEGORY_RANGE.begin - 2)
      assert !category.save
      assert_equal "must be between #{Category::CATEGORY_RANGE.begin} and #{Category::CATEGORY_RANGE.end}", category.errors.on(:position)
    end

    assert_no_difference 'Category.count' do
      category = Category.new(:name => 'New Category',
                              :position => Category::CATEGORY_RANGE.end + 1)
      assert !category.save
      assert_equal "must be between #{Category::CATEGORY_RANGE.begin} and #{Category::CATEGORY_RANGE.end}", category.errors.on(:position)
    end
  end

end
