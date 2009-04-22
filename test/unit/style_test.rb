# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class StyleTest < ActiveSupport::TestCase

  def setup
    @good_award_id = awards(:SPC).id
    @existing_style_name = styles(:style_23).name
    @good_category = categories(:specialty).position
    @new_category = Category.find(:first, :order => 'position DESC').position + 1
  end

  def test_should_create_new_style
    assert_difference 'Style.count' do
      style = Style.new(:name => 'New Style',
                        :bjcp_category => @new_category,
                        :bjcp_subcategory => 'A',
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'o')
      assert style.save
    end
  end

  def test_should_not_create_with_duplicate_style_id
    assert_no_difference 'Style.count' do
      style = Style.new(:name => 'New Style',
                        :bjcp_category => 23,
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'r')
      assert !style.save
      assert_equal 'Style category 23 already exists', style.errors.on(:base)
    end
  end

  def test_should_not_create_with_duplicate_style_id_with_subcategory
    assert_no_difference 'Style.count' do
      style = Style.new(:name => 'New Style',
                        :bjcp_category => 1,
                        :bjcp_subcategory => 'A',
                        :description_url => 'http://www.bjcp.org/finalstyles/Category1.php',
                        :award_id => @good_award_id,
                        :mcab_style => true,
                        :styleinfo => 'n')
      assert !style.save
      assert_equal 'Style category 1A already exists', style.errors.on(:base)
    end
  end

  def test_should_not_create_with_duplicate_style_name
    assert_no_difference 'Style.count' do
      style = Style.new(:name => @existing_style_name,
                        :bjcp_category => @new_category,
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'r')
      assert !style.save
      assert_equal 'already exists', style.errors.on(:name)
    end
  end

  def test_not_create_when_name_differs_only_in_case
    assert_no_difference 'Style.count' do
      style = Style.new(:name => @existing_style_name.downcase,
                        :bjcp_category => 23,
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'r')
      assert !style.save
      assert_equal 'already exists', style.errors.on(:name)
    end
  end

  def test_not_create_when_name_differs_only_in_whitespace
    assert_no_difference 'Style.count' do
      style = Style.new(:name => " #{@existing_style_name.gsub(' ', '   ')} ",
                        :bjcp_category => 23,
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'r')
      assert !style.save
      assert_equal 'already exists', style.errors.on(:name)
    end
  end

  def test_should_not_create_with_missing_name
    assert_no_difference 'Style.count' do
      style = Style.new(:bjcp_category => @good_category,
                        :bjcp_subcategory => 'A',
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'r')
      assert !style.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), style.errors.on(:name)
    end
  end

  def test_should_not_create_with_missing_bjcp_category
    assert_no_difference 'Style.count' do
      style = Style.new(:name => 'New Style',
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'o')
      assert !style.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), style.errors.on(:bjcp_category)
    end
  end

  def test_should_not_create_with_invalid_bjcp_category
    assert_no_difference 'Style.count' do
      style = Style.new(:name => 'New Style',
                        :bjcp_category => '23A',
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'r')
      assert !style.save
      assert_equal I18n.t('activerecord.errors.messages.not_a_number'), style.errors.on(:bjcp_category)
    end
  end

  def test_should_not_create_when_bjcp_category_is_out_of_range
    assert_no_difference 'Style.count' do
      style = Style.new(:name => 'New Style',
                        :bjcp_category => Category::CATEGORY_RANGE.last + 1,
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'r')
      assert !style.save
      assert_equal "must be between #{Category::CATEGORY_RANGE.begin} and #{Category::CATEGORY_RANGE.end}", style.errors.on(:bjcp_category)
    end
  end

  def test_should_not_create_with_invalid_bjcp_subcategory
    assert_no_difference 'Style.count' do
      style = Style.new(:name => 'New Style',
                        :bjcp_category => @good_category,
                        :bjcp_subcategory => Category::SUBCATEGORY_RANGE.end.succ,
                        :description_url => 'http://www.bjcp.org/finalstyles/Category23.php',
                        :award_id => @good_award_id,
                        :mcab_style => false,
                        :styleinfo => 'r')
      assert !style.save
      assert_equal "must be between #{Category::SUBCATEGORY_RANGE.begin} and #{Category::SUBCATEGORY_RANGE.end}", style.errors.on(:bjcp_subcategory)
    end
  end

  def test_should_not_create_with_invalid_urls
    urls = [ 'sftp://ftp.bjcp.org/styles/Category23.txt', # No sftp protocol
             'style/new_style',                           # No Leading /
             '/style/new_style/',                         # Trailing /
             '/style/new_style/trailing junk' ]           # Extra cruft
    urls.each do |url|
      assert_no_difference 'Style.count' do
        style = Style.new(:name => 'New Style',
                          :bjcp_category => @good_category,
                          :bjcp_subcategory => 'A',
                          :description_url => url,
                          :award_id => @good_award_id,
                          :mcab_style => false,
                          :styleinfo => 'r')
        assert !style.save
        assert_equal 'is not a properly formatted URL', style.errors.on(:description_url)
      end
    end
  end

  def test_should_create_with_valid_urls
    style_name = 'New Style 1'
    subcategory = 'A'
    # WARNING: A max of 6 URLs is allowed since subcategories only range from A to F
    urls = [ 'http://www.bjcp.org/finalstyles/Category23.php',
             'https://www.bjcp.org/finalstyles/Category23.php',
             'ftp://ftp.bjcp.org/finalstyles/Category23.txt',
             '/styles/new_style' ]
    urls.each do |url|
      assert_difference 'Style.count' do
        style = Style.new(:name => style_name,
                          :bjcp_category => @good_category,
                          :bjcp_subcategory => subcategory,
                          :description_url => url,
                          :award_id => @good_award_id,
                          :mcab_style => false,
                          :styleinfo => 'r')
        assert style.save, "Error saving #{style.name} as category #{style.bjcp_category}#{style.bjcp_subcategory} with URL #{style.description_url}"
        assert !style.errors.invalid?(:name)
        assert !style.errors.invalid?(:bjcp_category)
        assert !style.errors.invalid?(:bjcp_subcategory)
        assert !style.errors.invalid?(:description_url)
        assert !style.errors.invalid?(:award_id)
      end

      style_name.succ!
      subcategory.succ!
    end
  end

end
