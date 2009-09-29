# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::PointAllocationsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table PointAllocation.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    last_record = PointAllocation.find(:first, :order => 'max_entries desc')
    min_entries = last_record.max_entries + 1
    max_entries = min_entries + 99
    organizer_points = last_record.organizer + 1.0
    staff_points = last_record.staff + 1.0
    judge_points = last_record.judge + 1.0

    assert_difference 'PointAllocation.count' do
      post :create, :record => { :min_entries => min_entries,
                                 :max_entries => max_entries,
                                 :organizer => organizer_points,
                                 :staff => staff_points,
                                 :judge => judge_points }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_point_allocations_path
  end

  def test_search
    value = "3.0"
    get :update_table, :search => value
    assert_redirected_to admin_point_allocations_path(:search => value)
  end

  def test_show
    assert_raise(ActionController::UnknownAction) do
      get :show, :id => point_allocations(:e1).id
    end
  end

  def test_edit
    get :edit, :id => point_allocations(:e1).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = point_allocations(:e1)
    assert_no_difference 'PointAllocation.count' do
      post :update, :id => record.id, :record => { :judge => record.judge + 0.5 }
    end
    assert_redirected_to admin_point_allocations_path
  end

  def test_delete
    record = point_allocations(:e1)
    assert_difference('PointAllocation.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_point_allocations_path
  end

end
