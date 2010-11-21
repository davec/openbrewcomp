# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ClubsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      # NB, the "other club" is excluded from the view
      assert_select_active_scaffold_index_table Club.count - 1
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
    assert_redirected_to admin_clubs_path
  end

  def test_search
    name = "rangers"
    get :index, :search => name
    assert_template 'list'
  end

  def test_show_action_should_not_be_recognized
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
    assert_redirected_to admin_clubs_path
  end

  def test_destroy
    record = clubs(:kgb)
    assert_difference('Club.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_clubs_path
  end

  def test_cannot_destroy_club_with_entries
    record = clubs(:ehc)
    delete :destroy, :id => record.id
    assert_redirected_to authorization_error_path
  end

end
