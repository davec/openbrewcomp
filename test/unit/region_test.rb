# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class RegionTest < ActiveSupport::TestCase

  def setup
    @BR = countries(:BR)
    @existing_region = regions(:US_WA)
    @new_region_name = 'Zippy'
    @new_region_code = 'ZI'
    @new_region_country = @BR
  end

  def test_should_create_new_region
    assert_difference 'Region.count' do
      region = Region.new(:name => @new_region_name,
                          :region_code => @new_region_code,
                          :country_id => @existing_region.country_id)
      assert region.save
    end
  end

  def test_should_create_region_with_region_code_that_is_unique_for_the_country_but_also_exists_in_another_country
    # NT is used in both Australia and Canada. It should not be an
    # error to add it to another country, such as Brazil, that does
    # not currently have a region code of NT.
    assert_difference 'Region.count' do
      region = Region.new(:name => 'Território do Norte',
                          :region_code => 'NT',
                          :country_id => @BR.id)
      assert region.save
    end
  end

  def test_should_not_create_duplicate_region_name_in_same_country
    assert_no_difference 'Region.count' do
      region = Region.new(:name => @existing_region.name,
                          :region_code => @new_region_code,
                          :country_id => @existing_region.country_id)
      assert !region.save
      assert_equal 'already exists', region.errors.on(:name)
    end
  end

  def test_should_not_create_region_name_that_differs_only_in_case
    assert_no_difference 'Region.count' do
      region = Region.new(:name => @existing_region.name.downcase,
                          :region_code => @new_region_code,
                          :country_id => @existing_region.country_id)
      assert !region.save
      assert_equal 'already exists', region.errors.on(:name)
    end
  end

  def test_should_not_create_region_name_that_differs_only_in_whitespace
    assert_no_difference 'Region.count' do
      region = Region.new(:name => " #{@existing_region.name.gsub(' ', '   ')} ",
                          :region_code => @new_region_code,
                          :country_id => @existing_region.country_id)
      assert !region.save
      assert_equal 'already exists', region.errors.on(:name)
    end
  end

  def test_should_not_create_duplicate_region_code_in_same_country
    assert_no_difference 'Region.count' do
      region = Region.new(:name => @new_region_name,
                          :region_code => @existing_region.region_code,
                          :country_id => @existing_region.country_id)
      assert !region.save
      assert_equal 'already exists', region.errors.on(:region_code)
    end
  end

  def test_should_not_create_with_missing_region_name
    assert_no_difference 'Region.count' do
      region = Region.new(:region_code => @new_region_code,
                          :country_id => @new_region_country.id)
      assert !region.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), region.errors.on(:name)
    end
  end

  def test_should_not_create_with_missing_region_code
    assert_no_difference 'Region.count' do
      region = Region.new(:name => @new_region_name,
                          :country_id => @new_region_country.id)
      assert !region.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), region.errors.on(:region_code)
    end
  end

  def test_should_not_create_with_missing_country
    assert_no_difference 'Region.count' do
      region = Region.new(:name => @new_region_name,
                          :region_code => @new_region_code)
      assert !region.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), region.errors.on(:country_id)
    end
  end

end
