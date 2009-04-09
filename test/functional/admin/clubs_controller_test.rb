# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/clubs_controller'

# Re-raise errors caught by the controller.
class Admin::ClubsController; def rescue_action(e) raise e end; end

class Admin::ClubsControllerTest < Test::Unit::TestCase

  def setup
    @controller = Admin::ClubsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Club.count - 1  # The "other club" is excluded from the view
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Club.count' do
      post :create, :record => { :name => 'New Club' }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_search
    get :update_table, :search => 'rangers'
    assert_response :success
    assert_template '_list'
  end

  def test_show
    assert_raise(ActionController::UnknownAction) do
      get :show, :id => clubs(:rangers).id
    end
  end

  def test_edit
    get :edit, :id => clubs(:rangers).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = clubs(:cch)
    assert_no_difference 'Club.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = clubs(:kgb)
    assert_difference('Club.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_cannot_destroy_club_with_entries
    record = clubs(:ehc)
    assert_raise(ActiveScaffold::RecordNotAllowed) do
      delete :destroy, :id => record.id
    end
  end

end
