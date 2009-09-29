# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::JudgingSessionsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @today = Date.today
    @good_session = judging_sessions(:first1)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table JudgingSession.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    description = 'New Judging Session'
    last_position = JudgingSession.count
    assert_difference 'JudgingSession.count' do
      post :create, :record => { :description => description, :date => @today }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_judging_sessions_path

    # Verify that the record's position is at the end of the list
    record = JudgingSession.find_by_description(description)
    assert_not_nil record
    assert_equal last_position+1, record.position
  end

  def test_search
    name = "Session"
    get :update_table, :search => name
    assert_redirected_to admin_judging_sessions_path(:search => name)
  end

  def test_show
    record = @good_session
    get :show, :id => record.id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    record = @good_session
    get :edit, :id => record.id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = @good_session
    assert_no_difference 'JudgingSession.count' do
      post :update, :id => record.id,
                    :record => { :description => "#{record.description} (modified)" }
    end
    assert_redirected_to admin_judging_sessions_path
  end

  def test_destroy_session_without_flights
    record = judging_sessions(:no_flights)
    assert_difference('JudgingSession.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_judging_sessions_path
  end

  def test_cannot_destroy_session_with_flights
    delete :destroy, :id => @good_session.id
    assert_redirected_to authorization_error_path
  end

end
