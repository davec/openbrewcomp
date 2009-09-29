# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::JudgesControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @seated_judge = judges(:recognized_judge)
    @non_seated_judge = judges(:standby)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table [ Judge.count, 100 ].min
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Judge.count' do
      post :create, :record => { :first_name => 'Fred',
                                 :last_name => 'Derf',
                                 :judge_rank => { :id => judge_ranks(:certified).id },
                                 :judge_number => 'A0987' }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_judges_path
  end

  def test_create_with_time_availability
    assert_difference [ 'Judge.count', 'TimeAvailability.count' ] do
      post :create, :record => {
                      :first_name => 'Fred',
                      :last_name => 'Derf',
                      :judge_rank => { :id => judge_ranks(:certified).id },
                      :judge_number => 'A0987',
                      :time_availabilities => {
                        1 => {
                          :start_time => (Date.tomorrow + 9.hours).to_s(:db),
                          :end_time => (Date.tomorrow + 17.hours).to_s(:db)
                        }
                      }
                    }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_judges_path
  end

  def test_create_with_category_preferences
    assert_difference [ 'Judge.count', 'CategoryPreference.count' ] do
      post :create, :record => {
                      :first_name => 'Fred',
                      :last_name => 'Derf',
                      :judge_rank => { :id => judge_ranks(:certified).id },
                      :judge_number => 'A0987',
                      :category_preferences => {
                        1 => { :category => { :id => categories(:sour).id } }
                      }
                    }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_judges_path
  end

  def test_search
    name = "pro"
    get :update_table, :search => name
    assert_redirected_to admin_judges_path(:search => name)
  end

  def test_show
    get :show, :id => @seated_judge.id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => @seated_judge.id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = @seated_judge
    assert_no_difference 'Judge.count' do
      post :update, :id => record.id,
                    :record => { :last_name => "#{record.last_name} Jr." }
    end
    assert_redirected_to admin_judges_path
  end

  def test_update_time_available
    record = @seated_judge
    assert_difference 'TimeAvailability.count' do
      post :update, :id => record.id,
                    :record => {
                      :time_availabilities => {
                        1 => {
                          "start_time" => (Date.tomorrow + 9.hours).to_s(:db),
                          "end_time" => (Date.tomorrow + 17.hours).to_s(:db)
                        }
                      }
                    }
    end
    assert_redirected_to admin_judges_path
  end

  def test_update_category_preferences
    record = @seated_judge
    assert_difference 'CategoryPreference.count' do
      post :update, :id => record.id,
                    :record => {
                      :category_preferences => {
                        1 => { :category => { :id => categories(:fruit).id } }
                      }
                    }
    end
    assert_redirected_to admin_judges_path
  end

  def test_destroy
    record = @non_seated_judge
    assert_difference('Judge.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_judges_path
  end

  def test_cannot_destroy_seated_judge
    delete :destroy, :id => @seated_judge.id
    assert_redirected_to authorization_error_path
  end

  def test_help
    get :help
    assert_response :success
    assert_template 'help'
  end

end
