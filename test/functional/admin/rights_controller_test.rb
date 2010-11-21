# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::RightsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Right.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Right.count' do
      post :create, :record => { :name => 'New Right',
                                 :description => 'New Right Description',
                                 :controller => 'testnew',
                                 :action => '*' }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_rights_path
  end

  def test_search
    name = rights(:testright).name
    get :index, :search => name
    assert_template 'list'
  end

  def test_show
    get :show, :id => rights(:testright).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => rights(:testright).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = rights(:testright)
    assert_no_difference 'Right.count' do
      post :update, :id => record.id,
                    :record => { :description => "#{record.description} (modified)" }
    end
    assert_redirected_to admin_rights_path
  end

  def test_destroy
    record = rights(:testright)
    assert_difference('Right.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_rights_path
  end

  def test_unauthorized_access
    # The news_admin account does not have access rights to the rights controller
    login_as(:news_admin)
    get :index
    assert_redirected_to authorization_error_path
  end

end
