# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/categories_controller'

# Re-raise errors caught by the controller.
class Admin::CategoriesController; def rescue_action(e) raise e end; end

class Admin::CategoriesControllerTest < Test::Unit::TestCase

  def setup
    @controller = Admin::CategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Category.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Category.count' do
      post :create, :record => { :name => 'New Category',
                                 :position => Category.maximum(:position)+1 }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_search
    get :update_table, :search => 'lager'
    assert_response :success
    assert_template '_list'
  end

  def test_show
    get :show, :id => categories(:light_lager).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => categories(:light_lager).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = categories(:light_lager)
    assert_no_difference 'Category.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = categories(:sour)
    assert_difference('Category.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_cannot_destroy_category_with_entries
    record = categories(:light_lager)
    assert_raise(ActiveScaffold::RecordNotAllowed) do
      delete :destroy, :id => record.id
    end
  end

end
