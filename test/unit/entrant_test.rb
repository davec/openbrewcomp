# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class EntrantTest < Test::Unit::TestCase

  def setup
    @USTX = regions(:US_TX)
    @CA = countries(:CA)
    @CAAB = regions(:CA_AB)
    @AUSA = regions(:AU_SA)
    @FI = countries(:FI)
    @KR = countries(:KR)
    @XB = countries(:XB)
    @IE = countries(:IE)
    @IEDU = regions(:IE_DU)
    @good_club_id = clubs(:rangers).id
    @good_user_id = users(:admin).id
    @other_club_id = clubs(:other).id
  end

  def test_should_add_new_entrant_and_set_postal_address_values_correctly
    assert_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '770010123',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert entrant.save
      assert_equal('77001-0123', entrant.postcode)
      assert_match(/John Doe/, entrant.postal_address)
      assert_no_match(/UNITED STATES/, entrant.postal_address)
    end
  end

  def test_should_add_new_entrant_and_create_new_club
    assert_difference [ 'Entrant.count', 'Club.count' ] do
      new_club_name = 'The Imaginary Club'
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '77001',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @other_club_id,
                            :club_name => new_club_name,
                            :user_id => @good_user_id)
      assert entrant.save
      assert_not_nil Club.find_by_name(new_club_name)
    end
  end

  def test_should_not_save_when_missing_entrant_name
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '77001',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal 'A name is required', entrant.errors.on(:base)
    end
  end

  def test_should_not_save_when_missing_team_name
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:is_team => true,
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '77001',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal "#{I18n.t('activerecord.errors.messages.blank')}", entrant.errors.on(:team_name)
    end
  end

  def test_should_not_save_when_missing_street_address
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '77001',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal "Street address #{I18n.t('activerecord.errors.messages.blank')}", entrant.errors.on(:base)
    end
  end

  def test_should_not_save_when_missing_city
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :region_id => @USTX.id,
                            :postcode => '77001',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal "#{I18n.t('activerecord.errors.messages.blank')}", entrant.errors.on(:city)
    end
  end

  def test_should_not_save_when_missing_state
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :postcode => '77001',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal 'A state is required', entrant.errors.on(:base)
    end
  end

  def test_should_not_save_when_missing_zipcode
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal "Zip code #{I18n.t('activerecord.errors.messages.blank')}", entrant.errors.on(:base)
    end
  end

  def test_should_not_save_when_missing_email_and_phone
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '77001',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal 'Either an email address or phone number is required', entrant.errors.on(:base)
    end
  end

  def test_should_not_save_when_other_club_name_is_missing
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '77001',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @other_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), entrant.errors.on(:club_name)
    end
  end

  def test_should_not_save_with_invalid_zipcode
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '77001234',
                            :email => 'nobody@nowhere.org',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal "Zip code #{I18n.t('activerecord.errors.messages.invalid')}", entrant.errors.on(:base)
    end
  end

  def test_should_not_save_with_invalid_email_address
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Doe',
                            :address1 => '123 Anywhere Dr.',
                            :address2 => 'Apt. 1',
                            :city => 'Houston',
                            :region_id => @USTX.id,
                            :postcode => '77001',
                            :email => 'nobody@nowhere',
                            :phone => '713-555-1212',
                            :club_id => @good_club_id,
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal Authentication.bad_email_message, entrant.errors.on(:email)
    end
  end

  def test_should_save_with_valid_foreign_country_data
    # We'll pick on Canada for this test
    assert_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'John',
                            :last_name => 'Jones',
                            :address1 => '2364 7th Concession',
                            :address2 => 'Site 6 Comp 10',
                            :address3 => 'RR 8 MSC Millarville',
                            :city => 'Millarville',
                            :region_id => @CAAB.id,
                            :postcode => 'T0L1K0',
                            :email => 'nobody@nowhere.ca',
                            :club_id => @other_club_id,
                            :club_name => 'Brewing Bandits',
                            :user_id => @good_user_id)
      assert entrant.save
      assert_equal('T0L 1K0', entrant.postcode)
      assert_match(/John Jones/, entrant.postal_address)
      assert_match(Regexp.new(@CAAB.country.name.upcase), entrant.postal_address)
    end
  end

  def test_should_save_when_country_has_no_postcode_canonify_pattern
    # We'll pick on Australia for this test
    assert_difference 'Entrant.count' do
      entrant = Entrant.new(:is_team => true,
                            :team_name => 'The Bruces',
                            :address1 => '91 Carrion St',
                            :city => 'Wagga Wagga',
                            :region_id => @AUSA.id,
                            :email => 'bruce@thebruces.com.au',
                            :postcode => '4321',
                            :club_id => @other_club_id,
                            :club_name => 'Brewing Bruces',
                            :user_id => @good_user_id)
      assert entrant.save
      assert_equal('4321', entrant.postcode)
      assert_match(/The Bruces/, entrant.postal_address)
      assert_match(Regexp.new(@AUSA.country.name.upcase), entrant.postal_address)
    end
  end

  def test_postal_address_for_country_with_native_name_in_label
    # Finland seems as good as any
    assert_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'Matti',
                            :last_name => 'Manninen',
                            :address1 => 'Mäkelänkatu 25 B 13',
                            :city => 'Helsinki',
                            :country_id => @FI.id,
                            :postcode => '00550',
                            :email => 'nobody@nowhere.fi',
                            :phone => '+358 204 51 4692',
                            :club_id => @other_club_id,
                            :club_name => 'Northern Brewers',
                            :user_id => @good_user_id)
      assert entrant.save
      assert_match(/Matti Manninen/, entrant.postal_address)
      assert_no_match(Regexp.new(@FI.name, true), entrant.postal_address)
      assert_match(/FINLAND/, entrant.postal_address)
    end
  end

  def test_postal_address_for_country_with_label_name_different_than_address_name
    # Use South Korea here
    assert_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'Park',
                            :last_name => 'Kil-Dong',
                            :address1 => '179-7 Seorin-dong',
                            :address2 => 'Jongno-gu',
                            :city => 'Seoul',
                            :country_id => @KR.id,
                            :postcode => '110-110',
                            :email => 'nobody@nowhere.co.kr',
                            :phone => '+82 2 2195 12 43',
                            :club_id => @other_club_id,
                            :club_name => 'DMZ Brewers of Doom',
                            :user_id => @good_user_id)
      assert entrant.save
      assert_match(/Park Kil-Dong/, entrant.postal_address)
      assert_no_match(Regexp.new(@KR.name, true), entrant.postal_address)
      assert_match(Regexp.new(@KR.country_address_name.upcase), entrant.postal_address)
    end
  end

  def test_country_with_no_city
    # Use British Antarctic Territory here
    assert_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'Edward',
                            :last_name => 'Scott',
                            :address1 => 'Base Camp',
                            :country_id => @XB.id,
                            :postcode => 'BIQQ 1ZZ',
                            :email => 'nobody@nowhere.co.uk',
                            :club_id => @other_club_id,
                            :club_name => 'Antarctic Brewing Club',
                            :user_id => @good_user_id)
      assert entrant.save
      assert_match(/Edward Scott/, entrant.postal_address)
      assert_match(Regexp.new(@XB.name.upcase), entrant.postal_address)
    end
  end

  def test_ireland_county_rules
    # Ireland has a special rule for county names in addresses:
    # if the city name is the same as the county name, then the
    # county name is excluded, otherwise it is required.

    # First test a case where no county is required
    assert_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'James',
                            :last_name => 'Murphy',
                            :address1 => '42 Morehampton Road',
                            :city => 'Dublin 12',
                            :country_id => @IE.id,
                            :email => 'nobody@nowhere.ie',
                            :club_id => @other_club_id,
                            :club_name => 'Gaelic Brewers',
                            :user_id => @good_user_id)
      assert entrant.save
      assert_no_match(/Co Dublin/, entrant.postal_address)
    end

    # Next test a case where a county is required, but don't specify it
    assert_no_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'Morris',
                            :last_name => 'Sullivan',
                            :address1 => '17 Rock Road',
                            :city => 'Blackrock',
                            :country_id => @IE.id,
                            :email => 'nobody@nowhere.ie',
                            :club_id => @other_club_id,
                            :club_name => 'Gaelic Brewers',
                            :user_id => @good_user_id)
      assert !entrant.save
      assert_equal 'A county is required', entrant.errors.on(:base)
    end

    # Next test a case where a county is required
    assert_difference 'Entrant.count' do
      entrant = Entrant.new(:first_name => 'Morris',
                            :last_name => 'Sullivan',
                            :address1 => '17 Rock Road',
                            :city => 'Blackrock',
                            :region_id => @IEDU.id,
                            :country_id => @IE.id,
                            :email => 'nobody@nowhere.ie',
                            :club_id => @other_club_id,
                            :club_name => 'Gaelic Brewers',
                            :user_id => @good_user_id)
      assert entrant.save
      assert_match(/Co Dublin/, entrant.postal_address)
    end
  end

end
