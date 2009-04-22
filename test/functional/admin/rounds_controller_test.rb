# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::RoundsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Round.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    name = 'Ultimate Round'
    last_position = Round.count
    assert_difference 'Round.count' do
      post :create, :record => { :name => name }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'

    # Verify that the record's position is at the end of the list
    record = Round.find_by_name(name)
    assert_not_nil record
    assert_equal last_position+1, record.position
  end

  def test_search
    get :update_table, :search => 'first'
    assert_response :success
    assert_template '_list'
  end

  def test_show
    assert_raise(ActionController::UnknownAction) do
      get :show, :id => rounds(:first).id
    end
  end

  def test_edit
    get :edit, :id => rounds(:first).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = rounds(:first)
    assert_no_difference 'Round.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (redux)" }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    # Modify configuration to allow deletion
    bos = flights(:bos)
    bos.update_attribute(:completed, false)
    bos.destroy
    # We should now be able to destroy the BOS round
    record = rounds(:bos)
    assert_difference('Round.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_cannot_destroy_round_with_flights
    record = rounds(:bos)
    delete :destroy, :id => record.id
    assert_redirected_to authorization_error_path
  end

end
