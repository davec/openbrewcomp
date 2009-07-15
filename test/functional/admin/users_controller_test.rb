# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::UsersControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table [ User.count, 100 ].min
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'User.count' do
      post :create, :record => { :login => 'testuser',
                                 :name => 'Test User',
                                 :password => 'password',
                                 :password_confirmation => 'password' }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_create_case_sensitivity
    login = 'TestUser'
    assert_difference 'User.count' do
      post :create, :record => { :login => login,
                                 :name => 'Test User',
                                 :password => 'password',
                                 :password_confirmation => 'password' }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'

    record = User.find_by_login(login.downcase)
    assert_not_nil record
    assert_equal login.downcase, record.login
  end

  def test_search
    get :update_table, :search => 'testuser7'
    assert_redirected_to :action => 'index'
  end

  def test_show
    get :show, :id => users(:testuser7).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => users(:testuser7).id
    assert_response :success
    assert_template 'update'
  end

  def test_cannot_edit_admin_if_not_admin
    login_as(:user_admin)
    get :edit, :id => users(:admin).id
    assert_redirected_to authorization_error_path
  end

  def test_update
    record = users(:testuser7)
    assert_no_difference 'User.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} is not a number" }
    end
    assert_redirected_to :action => 'index'
  end

  def test_update_admin
    record = users(:admin)
    post :update, :id => record.id,
                  :record => { :email => 'foo@example.com' }
    assert_redirected_to :action => 'index'
  end

  def test_cannot_update_admin_if_not_admin
    login_as(:user_admin)
    record = users(:admin)
    post :update, :id => record.id,
                  :record => { :email => 'foo@example.com' }
    assert_redirected_to authorization_error_path
  end

  def test_cannot_rename_admin
    record = users(:admin)
    post :update, :id => record.id,
                  :record => { :login => 'nimda' }
    assert_response :success
    assert_template '_messages'
    assert_match /The admin account cannot be renamed/, @response.body
  end

  def test_destroy
    record = users(:testuser7)
    assert_difference('User.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index'
  end

  def test_cannot_destroy_admin_as_admin
    delete :destroy, :id => users(:admin).id
    assert_redirected_to authorization_error_path
  end

  def test_cannot_destroy_admin_as_user_admin
    delete :destroy, :id => users(:admin).id
    assert_redirected_to authorization_error_path
  end

  def test_cannot_destroy_self
    login_as(:user_admin)
    delete :destroy, :id => users(:user_admin).id
    assert_redirected_to authorization_error_path
  end

end
