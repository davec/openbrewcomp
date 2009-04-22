# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::StylesControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Style.count' do
      post :create, :record => { :name => 'New Style',
                                 :bjcp_category => categories(:first_time).position + 1,
                                 :bjcp_subcategory => '',
                                 :description_url => '/styles/new',
                                 :award => { :id => awards(:first_time).id.to_s },
                                 :mcab_style => false,
                                 :styleinfo => 'o' }
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
    get :show, :id => styles(:style_1A).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => styles(:style_1A).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = styles(:style_1A)
    assert_no_difference 'Style.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = styles(:style_17A)
    assert_difference('Style.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_cannot_destroy_style_with_entries
    record = styles(:style_1A)
    delete :destroy, :id => record.id
    assert_redirected_to authorization_error_path
  end

end
