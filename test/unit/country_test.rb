# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < ActiveSupport::TestCase

  def setup
    @US = countries(:US)
    @CA = countries(:CA)
    @AU = countries(:AU)
    @DE = countries(:DE)
    @existing_country_name = @US.name
    @existing_country_code = @US.country_code
    @new_country_name = 'Whicker Island'
    @new_country_code = 'WI'
  end

  def test_should_add_new_country
    assert_difference 'Country.count' do
      country = Country.new(:name => @new_country_name,
                            :country_code => @new_country_code)
      assert country.save
    end
  end

  def test_should_not_add_when_name_differs_only_in_case
    assert_no_difference 'Country.count' do
      country = Country.new(:name => @existing_country_name.downcase,
                            :country_code => @new_country_code)
      assert !country.save
      assert_equal 'already exists', country.errors.on(:name)
    end
  end

  def test_should_not_add_when_name_differs_only_in_whitespace
    assert_no_difference 'Country.count' do
      country = Country.new(:name => " #{@existing_country_name.gsub(' ', '   ')} ",
                            :country_code => @new_country_code)
      assert !country.save
      assert_equal 'already exists', country.errors.on(:name)
    end
  end

  def test_should_not_add_duplicate_country_name
    assert_no_difference 'Country.count' do
      country = Country.new(:name => @existing_country_name,
                            :country_code => @new_country_code)
      assert !country.save
      assert_equal 'already exists', country.errors.on(:name)
    end
  end

  def test_should_not_add_duplicate_country_code
    assert_no_difference 'Country.count' do
      country = Country.new(:name => @new_country_name,
                            :country_code => @existing_country_code)
      assert !country.save
      assert_equal 'already exists', country.errors.on(:country_code)
    end
  end

  def test_should_not_add_invalid_country_code
    assert_no_difference 'Country.count' do
      country = Country.new(:name => @new_country_name,
                            :country_code => 'X')
      assert !country.save
      assert_equal I18n.t('activerecord.errors.messages.invalid'), country.errors.on(:country_code)
    end
  end

  def test_should_not_add_when_country_name_is_missing
    assert_no_difference 'Country.count' do
      country = Country.new(:country_code => @new_country_code)
      assert !country.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), country.errors.on(:name)
    end
  end

  def test_should_not_add_when_country_code_is_missing
    assert_no_difference 'Country.count' do
      country = Country.new(:name => @new_country_name)
      assert !country.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), country.errors.on(:country_code)
    end
  end

  def test_should_not_add_when_postcode_pattern_is_missing
    assert_no_difference 'Country.count' do
      country = Country.new(:name => @new_country_name,
                            :country_code => @new_country_code,
                            :postcode_canonify => "'\\1-\\2'.upcase")
      assert !country.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), country.errors.on(:postcode_pattern)
    end
  end

  def test_valid_postcodes
    assert @US.validate_postcode('12345-6789')
    assert @CA.validate_postcode('A2C 4E6')
    assert '12345-6789', @US.canonicalize_postcode('123456789')
    assert 'A2C 4E6', @CA.canonicalize_postcode('a2c4e6')

    # Test additional code paths:
    # 1. The postcode pattern for AU is specified as /.../
    # 2. The postcode pattern for DE is specified as %r{...}
    assert @AU.validate_postcode('1234')
    assert @DE.validate_postcode('12345')
  end

  def test_invalid_postcodes
    assert !@US.validate_postcode('A2C 4E6')
    assert !@CA.validate_postcode('12345-6789')
    assert !@US.canonicalize_postcode('A2C 4E6')
    assert !@CA.canonicalize_postcode('12345-6789')
  end

  def test_postcode_regexp_parsing
    assert Country.parse_regexp('').nil?
    assert '/^\\d{5}$/', Country.parse_regexp('^\\d{5}$').inspect
    assert '/^\\d{5}$/', Country.parse_regexp('/^\\d{5}$/').inspect
    assert '/^\\d{5}$/', Country.parse_regexp('%r{^\\d{5}$}').inspect
    assert '/^\\d{5}$/ix', Country.parse_regexp('/^\\d{5}$/ix').inspect
    assert '/^\\d{5}$/m', Country.parse_regexp('%r{^\\d{5}$}m').inspect
  end

end
