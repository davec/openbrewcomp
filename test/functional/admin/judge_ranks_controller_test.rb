# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::JudgeRanksControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table JudgeRank.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    description = 'New Rank'
    expected_position = JudgeRank.maximum(:position)+1
    assert_difference 'JudgeRank.count' do
      post :create, :record => { :description => description }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_judge_ranks_path

    # Verify that the record's position is at the end of the list
    record = JudgeRank.find_by_description(description)
    assert_not_nil record
    assert_equal expected_position, record.position
  end

  def test_search
    name = "master"
    get :index, :search => name
    assert_template 'list'
  end

  def test_show
    assert_raise(ActionController::UnknownAction) do
      get :show, :id => judge_ranks(:novice).id
    end
  end

  def test_edit
    get :edit, :id => judge_ranks(:novice).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = judge_ranks(:national)
    assert_no_difference 'JudgeRank.count' do
      post :update, :id => record.id,
                    :record => { :description => "#{record.description} (modified)" }
    end
    assert_redirected_to admin_judge_ranks_path
  end

  def test_destroy
    record = judge_ranks(:na)
    assert_difference('JudgeRank.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_judge_ranks_path
  end

end
