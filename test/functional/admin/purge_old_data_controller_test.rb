# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/purge_old_data_controller'

# Re-raise errors caught by the controller
class Admin::PurgeOldDataController; def rescue_action(e) raise e end; end

class Admin::PurgeOldDataControllerTest < Test::Unit::TestCase
  # PurgeOldData#zap (called from PurgeOldDataController#purge) uses a
  # DB transaction for its processing so transactional fixtures must be
  # disabled for this test suite.
  self.use_transactional_fixtures = false
  
  def setup
    @controller = Admin::PurgeOldDataController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)

    # Since we change the competition data during some of the tests, it must
    # be reloaded prior to each test.
    CompetitionData.reload!
  end

  def test_index_during_online_registration
    # The competition_data fixture is setup so that today occurs during
    # the open registration period.
    get :index
    assert_response :success

    # Validate the page contents
    assert_select 'html > head > title', 'Purge Old Data'
    assert_select 'div#content' do
      assert_select 'h1', 'Purge Old Data'
      assert_select 'div#purge-form', :count => 0
    end
  end

  def test_index_between_online_entry_registration_and_competition_date
    # Initialize the registration times to be in the past and the competition dates to be in the future.
    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = 5.weeks.ago.utc
    cd.entry_registration_end_time_utc = 1.week.ago.utc
    cd.competition_date = 1.week.from_now.to_date

    get :index
    assert_response :success

    # Validate the page contents
    assert_select 'html > head > title', 'Purge Old Data'
    assert_select 'div#content' do
      assert_select 'h1', 'Purge Old Data'
      assert_select 'div#purge-form', :count => 0
    end
  end

  def test_index_after_competition_date
    # Initialize the registration and competition dates to be in the past
    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = 6.weeks.ago.utc
    cd.entry_registration_end_time_utc = 2.weeks.ago.utc
    cd.competition_date = 1.day.ago.to_date

    get :index
    assert_response :success

    # Validate the page contents
    assert_select 'html > head > title', 'Purge Old Data'
    assert_select 'div#content' do
      assert_select 'h1', 'Purge Old Data'
      assert_select 'div#purge-form' do
        assert_select 'form[method=post]', :count => 1
      end
    end
  end

  def test_purge
    post :purge
    assert_redirected_to admin_path
    assert_equal 'Successfully purged old data', flash[:notice]
  end

end
