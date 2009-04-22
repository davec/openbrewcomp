# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::AwardsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Award.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Award.count' do
      post :create, :record => { :name => 'New Award',
                                 :position => awards(:first_time).position + 1,
                                 :category => { :id => categories(:first_time).id.to_s } }
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
    get :show, :id => awards(:PILS).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => awards(:PILS).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = awards(:PILS)
    assert_no_difference 'Award.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = awards(:SOUR)
    assert_difference('Award.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_cannot_destroy_award_with_entries
    record = awards(:LL)
    delete :destroy, :id => record.id
    assert_redirected_to authorization_error_path
  end

end
