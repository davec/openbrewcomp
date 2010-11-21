# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::RolesControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Role.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Role.count' do
      post :create, :record => { :name => 'New Role',
                                 :description => 'New Role Description' }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_roles_path
  end

  def test_search
    name = roles(:testrole).name
    get :index, :search => name
    assert_template 'list'
  end

  def test_show
    get :show, :id => roles(:testrole).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => roles(:testrole).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = roles(:testrole)
    assert_no_difference 'Role.count' do
      post :update, :id => record.id,
                    :record => { :description => "#{record.description} (modified)" }
    end
    assert_redirected_to admin_roles_path
  end

  def test_destroy
    record = roles(:testrole)
    assert_difference('Role.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_roles_path
  end

  def test_non_admin_access
    login_as(:testuser1)
    get :index
    assert_redirected_to authorization_error_path
  end

end
