# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CountriesControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table [ Country.count, 100 ].min
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Country.count' do
      post :create, :record => { :name => 'A Country',
                                 :country_code => 'AC' }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_search
    get :update_table, :search => 'island'
    assert_response :success
    assert_template '_list'
  end

  def test_show
    get :show, :id => countries(:CA).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => countries(:CA).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = countries(:CA)
    assert_no_difference 'Country.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = countries(:AQ)
    assert_difference('Country.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_cannot_destroy_country_with_entrants
    record = countries(:CA)
    delete :destroy, :id => record.id
    assert_redirected_to authorization_error_path
  end

end
