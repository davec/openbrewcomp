# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class RegisterControllerTest < ActionController::TestCase

  def setup
    # Since we're mucking around with the competition data, it needs to be
    # reloaded prior to each test.
    CompetitionData.reload!
    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page title
    assert_select 'html > head > title', "#{@competition_name} Registration"
    assert_select 'div#content > h1', "#{@competition_name} Registration"
  end

  def test_forms
    get :forms
    assert_response :success

    # Verify the page title
    assert_select 'html > head > title', "#{@competition_name} Entry Forms"
    assert_select 'div#content > h1', "#{@competition_name} Entry Forms"
  end

  def test_online
    get :online
    assert_redirected_to login_path
  end

  # NOTE: When testing the online registration page with a logged-in user,
  # the default CompetitionData fixture specifies a time range that starts
  # before the current time and ends after the current time.

  def test_online_logged_in
    login_as(:testuser1)

    get :online
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Online Registration"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Online Registration"
      assert_select 'ol#online-registration' do
        assert_select 'li#online-entries-item > div#online-entries' do
          assert_select 'div div#content', false, 'Nested page found, probable authorization failure'
          assert_select 'div > div.active-scaffold', 1, 'Nested form missing'
        end
        assert_select 'li#online-regform-item', 1
        assert_select 'li#online-send-item', 1
        assert_select 'li#online-judges-item > div#online-judges' do
          assert_select 'div div#content', false, 'Nested page found, probable authorization failure'
          assert_select 'div > div.active-scaffold', 1, 'Nested form missing'
        end
      end
    end
  end

  def test_online_nil_start_and_end_times
    login_as(:admin)

    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = nil
    cd.entry_registration_end_time_utc = nil
    cd.judge_registration_start_time_utc = nil
    cd.judge_registration_end_time_utc = nil

    get :online
    assert_response :success

    # Verify the correct status text exists
    assert_select 'div#content' do
      assert_select 'p', Regexp.new(CompetitionData::REGISTRATION_STATUS_UNKNOWN)
      assert_select 'p + p#registration-countdown', 0
      assert_select 'div#online-entries', 0
    end
  end

  def test_nil_start_time
    login_as(:admin)

    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = nil
    cd.entry_registration_end_time_utc = 1.week.from_now.utc
    cd.judge_registration_start_time_utc = nil
    cd.judge_registration_end_time_utc = 1.week.from_now.utc
    cd.local_timezone = 'UTC'

    get :online
    assert_response :success

    # Verify the online-entries div exists
    assert_select 'div#online-entries', 1
  end

  def test_nil_end_time
    login_as(:admin)

    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = 1.week.ago.utc
    cd.entry_registration_end_time_utc = nil
    cd.judge_registration_start_time_utc = 1.week.ago.utc
    cd.judge_registration_end_time_utc = nil
    cd.local_timezone = 'UTC'

    get :online
    assert_response :success

    # Verify the online-entries div exists
    assert_select 'div#online-entries', 1
  end

  def test_online_future_start_time_more_than_2_weeks_away
    login_as(:admin)

    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = 4.weeks.from_now.utc
    cd.entry_registration_end_time_utc = 8.weeks.from_now.utc
    cd.judge_registration_start_time_utc = 4.weeks.from_now.utc
    cd.judge_registration_end_time_utc = 8.weeks.from_now.utc
    cd.local_timezone = 'UTC'

    get :online
    assert_response :success

    # Verify the correct status text exists
    assert_select 'div#content' do
      assert_select 'p', Regexp.new(CompetitionData::REGISTRATION_STATUS_FUTURE)
      assert_select 'p#registration-countdown', 0
      assert_select 'div#online-entries', 0
    end
  end

  def test_online_future_start_time_less_than_2_weeks_away
    login_as(:admin)

    now = Time.now
    start_time = now + 1.week
    end_time = now + 4.weeks

    expected_opening_message = "Registration will open in #{TimeInterval.difference_in_words(now, start_time)}."

    cd = CompetitionData.instance
    cd.local_timezone = 'UTC' #"Etc/GMT#{'%+d' % (Time.now.gmt_offset/3600)}"
    cd.entry_registration_start_time = start_time
    cd.entry_registration_end_time = end_time
    cd.judge_registration_start_time = start_time
    cd.judge_registration_end_time = end_time

    get :online
    assert_response :success

    # Verify the correct status text exists
    assert_select 'div#content' do
      assert_select 'p', Regexp.new(CompetitionData::REGISTRATION_STATUS_FUTURE)
      assert_select 'p#registration-countdown', 1
      assert_select 'p#registration-countdown', expected_opening_message
      assert_select 'div#online-entries', 0
    end
  end

  def test_online_past_end_time
    login_as(:admin)

    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = 1.week.ago.utc
    cd.entry_registration_end_time_utc = 1.hour.ago.utc
    cd.judge_registration_start_time_utc = 1.week.ago.utc
    cd.judge_registration_end_time_utc = 1.hour.ago.utc
    cd.local_timezone = 'UTC'

    get :online
    assert_response :success

    # Verify the correct status text exists
    assert_select 'div#content' do
      assert_select 'p', Regexp.new(CompetitionData::REGISTRATION_STATUS_PAST)
      assert_select 'p#registration-countdown', 0
      assert_select 'div#online-entries', 0
    end
  end

  def test_judge_confirmation_with_no_key
    assert_raise(ActionController::RoutingError) do
      get :judge_confirmation
    end
  end

  def test_judge_confirmation_with_good_key
    # HACK: This isn't really realistic since the user is not very likely to
    # be logged in at this point, but it does allow us to perform a quick
    # test of the judge_confirmation method.
    login_as(:testuser1)

    get :judge_confirmation, :key => judges(:recognized_judge).access_key
    assert_redirected_to online_registration_path
  end

  def test_judge_confirmation_with_bad_key
    # HACK: This isn't really realistic since the user is not very likely to
    # be logged in at this point, but it does allow us to perform a quick
    # test of the judge_confirmation method.
    login_as(:testuser1)

    get :judge_confirmation, :key => '0123456789abcdeffedcba9876543210'
    assert_redirected_to online_registration_path
    assert_equal 'Confirmation key was not found', flash[:warning]
  end

end
