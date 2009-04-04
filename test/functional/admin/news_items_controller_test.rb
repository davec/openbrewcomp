# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/news_items_controller'

# Re-raise errors caught by the controller.
class Admin::NewsItemsController; def rescue_action(e) raise e end; end

class Admin::NewsItemsControllerTest < Test::Unit::TestCase

  def setup
    @controller = Admin::NewsItemsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table [ NewsItem.count, 20 ].min
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'NewsItem.count' do
      post :create, :record => { :title => 'New News Item',
                                 :description_raw => 'Testing news item creation' }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_search
    get :update_table, :search => 'News Item 2'
    assert_response :success
    assert_template '_list'
  end

  def test_show
    get :show, :id => news_items(:post3).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => news_items(:post4).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = news_items(:post5)
    assert_no_difference 'NewsItem.count' do
      post :update, :id => record.id,
                    :record => { :title => "#{record.title} (modified)",
                                 :description_raw => "#{record.description_raw} (modified)" }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = news_items(:post6)
    assert_difference('NewsItem.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

end
