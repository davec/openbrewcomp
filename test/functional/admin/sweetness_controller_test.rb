# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::SweetnessControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Sweetness.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    description = 'New Sweetness'
    last_position = Sweetness.count
    assert_difference 'Sweetness.count' do
      post :create, :record => { :description => description }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'

    # Verify that the record's position is at the end of the list
    record = Sweetness.find_by_description(description)
    assert_not_nil record
    assert_equal last_position+1, record.position
  end

  def test_search
    get :update_table, :search => 'medium'
    assert_redirected_to :action => 'index'
  end

  def test_show_action_should_not_be_recognized
    assert_raise(ActionController::UnknownAction) do
      get :show, :id => sweetness(:medium).id
    end
  end

  def test_edit
    get :edit, :id => sweetness(:medium).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = sweetness(:medium)
    assert_no_difference 'Sweetness.count' do
      post :update, :id => record.id,
                    :record => { :description => "#{record.description} (modified)" }
    end
    assert_redirected_to :action => 'index'
  end

  def test_destroy
    record = sweetness(:medium)
    assert_difference('Sweetness.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index'
  end

end
