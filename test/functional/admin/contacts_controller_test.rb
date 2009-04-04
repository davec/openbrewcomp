# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/contacts_controller'

# Re-raise errors caught by the controller.
class Admin::ContactsController; def rescue_action(e) raise e end; end

class Admin::ContactsControllerTest < Test::Unit::TestCase

  def setup
    @controller = Admin::ContactsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
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
    assert_redirected_to :action => 'index'
  end

  def test_search
    get :update_table, :search => 'coordinator'
    assert_response :success
    assert_template '_list'
  end

  def test_show
    get :show, :id => contacts(:coordinator).id
    assert_response :success
    assert_template 'show'
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
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = contacts(:coordinator)
    assert_difference('Contact.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

end
