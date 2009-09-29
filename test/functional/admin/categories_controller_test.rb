# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CategoriesControllerTest < ActionController::TestCase

  def setup
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
    assert_redirected_to admin_categories_path
  end

  def test_search
    name = "lager"
    get :update_table, :search => name
    assert_redirected_to admin_categories_path(:search => name)
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
    assert_redirected_to admin_categories_path
  end

  def test_destroy
    record = categories(:sour)
    assert_difference('Category.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_categories_path
  end

  def test_cannot_destroy_category_with_entries
    record = categories(:light_lager)
    delete :destroy, :id => record.id
    assert_redirected_to authorization_error_path
  end

end
