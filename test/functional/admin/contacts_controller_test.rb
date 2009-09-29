# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ContactsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Contact.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Contact.count' do
      post :create, :record => { :role => 'testrole',
                                 :name => 'Test Name',
                                 :email => 'testmail@example.com' }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_contacts_path
  end

  def test_search
    name = "coordinator"
    get :update_table, :search => name
    assert_redirected_to admin_contacts_path(:search => name)
  end

  def test_show
    assert_raise(ActionController::UnknownAction) do
      get :show, :id => contacts(:coordinator).id
    end
  end

  def test_edit
    get :edit, :id => contacts(:coordinator).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = contacts(:coordinator)
    assert_no_difference 'Contact.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to admin_contacts_path
  end

  def test_destroy
    record = contacts(:coordinator)
    assert_difference('Contact.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_contacts_path
  end

end
