# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::FlightsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page title
    assert_select 'html > head > title', "#{@competition_name} Flights"
    assert_select 'div#content > h1', "#{@competition_name} Flights"
  end

  def test_should_show_assign_page_with_form_hidden
    get :assign
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Flight Assignments"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Flight Assignments"
      assert_select 'div#auto-assign-flights[style="display:none"] > div#auto-assign-form > form[method=post]'
      assert_select 'div#flight-assignments-view > ol' do
        assert_select 'li', :count => Award.find_public_awards.length
      end
    end
  end

  def test_should_show_assign_page_with_form_visible
    # Remove all flights
    Judging.destroy_all
    Flight.destroy_all

    get :assign
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Flight Assignments"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Flight Assignments"
      assert_select 'div#auto-assign-flights[style="display:none"]', 0
      assert_select 'div#auto-assign-flights > div#auto-assign-form > form[method=post]'
      assert_select 'div#flight-assignments-view > ol' do
        assert_select 'li', :count => Award.find_public_awards.length
      end
    end
  end

  def test_should_auto_assign_flights
    # Remove all flights
    Judging.destroy_all
    Flight.destroy_all

    post :assign, :flight => { :min => 4, :max => 8 }
    assert_response :success
    assert_template 'assign'
  end

  def test_auto_assign_flight_errors
    # Remove all flights
    Judging.destroy_all
    Flight.destroy_all

    post :assign
    assert_equal 'Must specify minimum and maximum values', flash[:errors]

    post :assign, :flight => { :min => '', :max => '' }
    assert_included 'The minimum number of entries must not be blank', flash[:errors]
    assert_included 'The maximum number of entries must not be blank', flash[:errors]

    post :assign, :flight => { :min => '2.5', :max => '7.5' }
    assert_included 'The minimum number of entries must be an integer value', flash[:errors]
    assert_included 'The maximum number of entries must be an integer value', flash[:errors]

    post :assign, :flight => { :min => '-1', :max => '-1' }
    assert_included 'The minimum number of entries must be greater than zero', flash[:errors]
    assert_included 'The maximum number of entries must be greater than zero', flash[:errors]

    post :assign, :flight => { :min => '4', :max => '4' }
    assert_equal 'The maximum number of entries must be greater than the minimum number of entries', flash[:errors]

    post :assign, :flight => { :min => '8', :max => '4' }
    assert_equal 'The maximum number of entries must be greater than the minimum number of entries', flash[:errors]

  end

  def test_manage
    get :manage
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Flight Management"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Flight Management"
      assert_select 'div#flight-management-menu > ul' do
        assert_select 'li', :count => 4
      end
    end
  end

  def test_tracking
    get :track
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Flight Tracker"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Flight Tracker"
      assert_select 'table#flight-tracker > tbody' do
        assert_select 'tr', :count => 1
        assert_select 'tr > td', :count => 4
        assert_select 'tr > td:nth-child(1) > span.completed', '10'
        assert_select 'tr > td:nth-child(2) > span.assigned',   '0'
        assert_select 'tr > td:nth-child(3) > span.unassigned', '0'
        assert_select 'tr > td:nth-child(4) > span.total',     '10'
      end
    end
  end

  def test_show_ineligible_judges
    award = awards(:LL)
    get :ineligible_judges, :award_id => award.id
    assert_response :success
    assert_select 'div.ineligible-judges'

    # Verify the page contents
    assert_select 'html > head > title', "Ineligible Judges for #{award.name}"
    assert_select 'div#content' do
      assert_select 'h1', "Ineligible Judges for #{award.name}"
      assert_select 'div.ineligible-judges', :count => 1
    end
  end

  def test_list_ineligible_judges
    get :list_ineligible_judges
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', 'Ineligible Judge List'
    assert_select 'div#content' do
      assert_select 'h1', 'Ineligible Judge List'
      assert_select 'div#ineligible-judge-list' do
        assert_select 'div.ineligible-judges', :count => Award.count
      end
    end
  end

  def test_list_all_flights
    get :all_flights
    assert_response :success
    assert_template 'all_flights'

    # NOTE: The following "standard" check doesn't work because the controller
    # is nested, and as a result its ID is not easily determined. For now, we
    # use an alternate method to verity the size of the flight list.
    #
    #assert_select 'div#content' do
    #  assert_select_active_scaffold_index_table Flight.count
    #end

    assert_select 'div#content > div#flight-management-view > div#flights-view > div' do
      assert_select 'div.active-scaffold-header > h2', 'Flights'
      assert_select 'div > table tbody.records > tr.record', :count => Flight.count
    end
  end

  def test_list_round_1_flights
    get :round_1
    assert_response :success
    assert_template 'round_flights'

    awards = Award.find_public_awards
    assert_select 'div#content > div#flight-management-view > div#flights-view > ul' do
      assert_select 'li', :count => awards.length
      awards.each do |award|
        expected_count = award.flights.select{|f| f.round == Round.first}.length
        assert_select "li#award#{award.id}-item > div.flights-for-award > div.active-scaffold" do
          assert_select 'div.active-scaffold-header > h2', award.name
          if expected_count > 0
            assert_select 'div > table > tbody.records > tr.record', :count => expected_count
          else
            assert_select 'div > table > tbody.messages' do
              assert_select 'tr', :count => 1
              assert_select 'p.empty-message', { :count => 1,
                                                 :text => I18n.t('active_scaffold.no_entries') }
            end
          end
        end
      end
    end
  end

  def test_list_round_2_flights
    get :round_2
    assert_response :success
    assert_template 'round_flights'

    awards = Award.find_public_awards
    assert_select 'div#content > div#flight-management-view > div#flights-view > ul' do
      assert_select 'li', :count => awards.length
      awards.each do |award|
        assert_select "li#award#{award.id}-item > div.flights-for-award > div.active-scaffold" do
          assert_select 'div.active-scaffold-header > h2', award.name
          unless award.flights.empty?
            assert_select 'div > table > tbody.records > tr.record', :count => 1
          else
            assert_select 'div > table > tbody.messages' do
              assert_select 'tr', :count => 1
              assert_select 'p.empty-message', { :count => 1,
                                                 :text => I18n.t('active_scaffold.no_entries') }
            end
          end
        end
      end
    end
  end

  def test_list_round_3_flights
    get :round_3
    assert_response :success
    assert_template 'round_flights'

    awards = Award.find_non_public_awards
    assert_select 'div#content > div#flight-management-view > div#flights-view > ul' do
      assert_select 'li', :count => awards.length
      awards.each do |award|
        assert_select "li#award#{award.id}-item > div.flights-for-award > div.active-scaffold" do
          assert_select 'div.active-scaffold-header > h2', award.name
          assert_select 'div > table > tbody.records > tr.record', :count => 1
        end
      end
    end
  end

  def test_list_round_3_flights_with_majority_of_second_round_flights_incomplete
    # Discard the BOS flight
    flight = flights(:bos)
    flight.update_attribute(:completed, false)
    flight.destroy
    # Mark all but one second round flight as incomplete
    Flight.all.select{|flight| flight.round == Round.second}.each_with_index{|flight,index| flight.update_attribute(:completed, false) if index > 0}

    # With no second round flights complete, the BOS flight list should be empty
    get :round_3
    assert_response :success
    assert_template 'round_flights'

    awards = Award.find_non_public_awards
    assert_select 'div#content > div#flight-management-view > div#flights-view > ul' do
      assert_select 'li', :count => awards.length
      awards.each do |award|
        assert_select "li#award#{award.id}-item > div.flights-for-award > div.active-scaffold" do
          assert_select 'div.active-scaffold-header > h2', award.name
          assert_select 'div > table > tbody.messages' do
            assert_select 'tr', :count => 1
            assert_select 'p.empty-message', { :count => 1,
                                               :text => I18n.t('active_scaffold.no_entries') }
          end
        end
      end
    end
  end

  def test_list_round_3_flights_with_majority_of_second_round_flights_complete
    # Discard the BOS flight
    flight = flights(:bos)
    flight.update_attribute(:completed, false)
    flight.destroy
    # Mark a second round flight as incomplete
    flights(:smoked).update_attribute(:completed, false)

    # With a majority of second round flights complete, the BOS flight list should be
    # generated, but the list should indicate that it is incomplete.
    get :round_3
    assert_response :success
    assert_template 'round_flights'

    awards = Award.find_non_public_awards
    assert_select 'div#content > div#flight-management-view > div#flights-view > ul' do
      assert_select 'li', :count => awards.length
      awards.each do |award|
        assert_select "li#award#{award.id}-item > div.flights-for-award > div.active-scaffold" do
          assert_select 'div.active-scaffold-header > h2', award.name
          assert_select 'div > table > tbody.records > tr.record', :count => 1 do
            assert_select 'td.status-column > span.incomplete', 'Incomplete'
          end
        end
      end
    end
  end

  def test_should_print_flight_sheets_for_single_flight
    get :print, :id => flights(:light_lager_1).id
    assert_response :success
    assert_pdf_response
  end

  def test_should_not_print_flight_sheets_for_invalid_flight
    get :print, :id => Flight.maximum(:id)+1
    assert_redirected_to not_found_error_path
  end

  def test_should_print_all_flight_sheets_for_round
    # HACK: Reset the BOS flight status to allow printing of the flight sheets
    flights(:bos).update_attribute(:completed, false)

    get :print, :round => rounds(:bos).position
    assert_response :success
    assert_pdf_response
  end

  def test_should_not_print_flight_sheets_for_invalid_round
    get :print, :round => 42
    assert_redirected_to not_found_error_path
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Flight.count' do
      post :create, :record => { :name => 'New Flight',
                                 :round => { :id => rounds(:first).id.to_s },
                                 :award => { :id => Award.find(:first, :order => 'id').id.to_s } }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_search
    get :update_table, :search => 'Best'
    assert_redirected_to :action => 'index'
  end

  def test_show
    get :show, :id => flights(:smoked_1).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => flights(:smoked).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = flights(:smoked)
    assert_no_difference 'Flight.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to :action => 'index'
  end

  def test_destroy
    record = flights(:bos)
    # HACK: Force the completed flag off so the flight can be deleted
    # (otherwise the completed flag prevents it from being deleted).
    record.update_attribute(:completed, false)
    assert_difference('Flight.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index'
  end

  def test_cannot_destroy_assigned_flight
    flight = flights(:bos)
    # HACK: Force the assigned flag on, and the completed flag off
    flight.update_attributes(:assigned => true, :completed => false)
    delete :destroy, :id => flight.id
    assert_redirected_to authorization_error_path
  end

  def test_cannot_destroy_completed_flight
    delete :destroy, :id => flights(:light_lager_2).id
    assert_redirected_to authorization_error_path
  end

end
