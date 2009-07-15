# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::RegionsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table [ Region.count, 100 ].min
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Region.count' do
      post :create, :record => { :name => 'Zippy',
                                 :region_code => 'ZI',
                                 :country => { :id => countries(:US).id } }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_search
    get :update_table, :search => 'territory'
    assert_redirected_to :action => 'index'
  end

  def test_show
    get :show, :id => regions(:US_WY).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => regions(:US_WY).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = regions(:US_WY)
    assert_no_difference 'Region.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to :action => 'index'
  end

  def test_destroy
    record = regions(:US_WY)
    assert_difference('Region.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index'
  end

  def test_cannot_destroy_region_with_entrants
    record = regions(:US_TX)
    delete :destroy, :id => record.id
    assert_redirected_to authorization_error_path
  end

end
