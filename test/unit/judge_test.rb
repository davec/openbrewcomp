# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class JudgeTest < ActiveSupport::TestCase

  def setup
    @USTX = regions(:US_TX)
    @recognized_id = judge_ranks(:recognized).id
    @national_id = judge_ranks(:national).id
    @novice_id = judge_ranks(:novice).id
    @experienced_id = judge_ranks(:experienced).id
    @good_judge_number = 'A0101'
    @bad_judge_number = 'xyzzy'
    @good_club_id = clubs(:rangers).id
    @good_user_id = users(:admin).id
    @other_club_id = clubs(:other).id
    Controller.admin_view = true  # Default to admin usage (override as necessary in individual tests)
  end

  def test_should_create_new_bjcp_judge_with_no_address_as_admin
    assert_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @recognized_id,
                        :judge_number => @good_judge_number,
                        :user_id => @good_user_id)
      assert judge.save
    end
  end

  def test_should_create_new_bjcp_judge_with_no_address_as_non_admin
    Controller.admin_view = false
    assert_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @recognized_id,
                        :judge_number => @good_judge_number,
                        :email => 'bozo@example.com',
                        :user_id => @good_user_id)
      assert judge.save
    end
  end

  def test_should_create_new_bjcp_judge_with_partial_address_as_admin
    assert_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @recognized_id,
                        :judge_number => @good_judge_number,
                        :city => 'Cut-n-Shoot',
                        :region_id => @USTX.id,
                        :user_id => @good_user_id)
      assert judge.save
    end
  end

  def test_should_not_create_new_bjcp_judge_with_partial_address_as_non_admin
    Controller.admin_view = false
    assert_no_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @recognized_id,
                        :judge_number => @good_judge_number,
                        :city => 'Cut-n-Shoot',
                        :region_id => @USTX.id,
                        :phone => '888 555-1212',
                        :user_id => @good_user_id)
      assert !judge.save
      assert judge.errors.on(:base).is_a?(Array)
      assert judge.errors.on(:base).include?("Street address #{I18n.t('activerecord.errors.messages.blank')}")
      assert judge.errors.on(:base).include?("Zip code #{I18n.t('activerecord.errors.messages.blank')}")
    end
  end

  def test_should_create_new_non_bjcp_judge_with_full_address_but_no_email_or_phone_as_admin
    assert_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @experienced_id,
                        :address1 => '1234 Crack House Lane',
                        :address2 => 'Apt. 23C',
                        :city => 'Houston',
                        :region_id => @USTX.id,
                        :postcode => '77005',
                        :user_id => @good_user_id)
      assert judge.save
    end
  end

  def test_should_not_create_new_non_bjcp_judge_with_full_address_but_no_email_or_phone_as_non_admin
    Controller.admin_view = false
    assert_no_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @experienced_id,
                        :address1 => '1234 Crack House Lane',
                        :address2 => 'Apt. 23C',
                        :city => 'Houston',
                        :region_id => @USTX.id,
                        :postcode => '77005',
                        :user_id => @good_user_id)
      assert !judge.save
      assert_equal 'Either an email address or a phone number is required', judge.errors.on(:base)
    end
  end

  def test_should_create_new_non_bjcp_judge_with_judge_number_but_discards_judge_number
    assert_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @experienced_id,
                        :judge_number => @good_judge_number,
                        :user_id => @good_user_id)
      assert judge.save
      # Verify that the judge number is not saved for a non-BJCP rank
      assert_nil judge.judge_number
    end
  end

  def test_should_not_create_bjcp_judge_without_judge_number
    assert_no_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @national_id,
                        :user_id => @good_user_id)
      assert !judge.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), judge.errors.on(:judge_number)
    end
  end

  def test_should_not_create_bjcp_judge_with_invalid_judge_number
    assert_no_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @national_id,
                        :judge_number => @bad_judge_number,
                        :user_id => @good_user_id)
      assert !judge.save
      assert_equal I18n.t('activerecord.errors.messages.invalid'), judge.errors.on(:judge_number)
    end
  end

  def test_should_not_create_judge_without_a_name
    assert_no_difference 'Judge.count' do
      judge = Judge.new(:judge_rank_id => @novice_id,
                        :user_id => @good_user_id)
      assert !judge.save
      assert_equal 'A name is required', judge.errors.on(:base)
    end
  end

  def test_should_allow_missing_last_name
    assert_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'Elvis',
                        :judge_rank_id => @novice_id,
                        :user_id => @good_user_id)
      assert judge.save
    end
  end

  def test_should_not_create_judge_with_invalid_email_address
    assert_no_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'Elvis',
                        :last_name => 'Sivle',
                        :judge_rank_id => @novice_id,
                        :email => 'elvis@graceland',
                        :user_id => @good_user_id)
      assert !judge.save
      #assert_equal I18n.t('activerecord.errors.messages.invalid'), judge.errors.on(:email)
      assert_equal Authentication.bad_email_message, judge.errors.on(:email)
    end
  end

  def test_should_allow_only_one_organizer
    organizer = judges(:organizer)
    assert organizer.organizer

    # Pick a random judge and try to "promote" to competition organizer
    # and verify failure.
    judge2 = Judge.find(:first, :conditions => [ 'organizer = ?' , false ])
    judge2.organizer = true
    assert !judge2.save
    assert_equal "#{organizer.name} is already defined as the competition organizer.", judge2.errors.on(:base)
  end

  def test_should_assign_staff_points
    judge = Judge.find(:first)
    judge.staff_points = 0.5
    assert judge.save
  end

  def test_should_not_allow_invalid_staff_point_values_to_be_assigned
    judge = Judge.find(:first)
    judge.staff_points = 0.3
    assert !judge.save
    assert_equal PointAllocation::FORMAT_ERROR, judge.errors.on(:staff_points)
  end

  def test_should_not_allow_excess_staff_points_to_be_assigned
    judge = Judge.find(:first)
    judge.staff_points = 6.5
    assert !judge.save
    assert_match /^must not exceed [0-9]\.[05]$/, judge.errors.on(:staff_points)
  end

  def test_should_not_create_judge_with_duplicate_judge_number
    assert_no_difference 'Judge.count' do
      judge = Judge.new(:first_name => 'New',
                        :last_name => 'Judge',
                        :judge_rank_id => @recognized_id,
                        :judge_number => judges(:national_judge).judge_number,
                        :user_id => @good_user_id)
      assert !judge.save
      assert_equal 'is already registered', judge.errors.on(:judge_number)
    end
  end

  def test_should_count_judges_with_email_addresses
    assert_equal Judge.email_count, Judge.count
  end

  def test_should_exclude_judges_without_email_addresses
    # Create judge without an email address
    Judge.create(:first_name => 'New',
                 :last_name => 'Judge',
                 :judge_rank_id => @experienced_id,
                 :address1 => '1234 Crack House Lane',
                 :address2 => 'Apt. 23C',
                 :city => 'Houston',
                 :region_id => @USTX.id,
                 :postcode => '77005',
                 :user_id => @good_user_id)
    assert_equal Judge.email_count, Judge.count - 1
  end

end
