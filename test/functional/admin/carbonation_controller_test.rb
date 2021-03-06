# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CarbonationControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table Carbonation.count
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    description = 'New Carbonation'
    last_position = Carbonation.count
    assert_difference 'Carbonation.count' do
      post :create, :record => { :description => description }
    end
    assert assigns(:record).valid?
    assert_redirected_to admin_carbonation_index_path

    # Verify that the record's position is at the end of the list
    record = Carbonation.find_by_description(description)
    assert_not_nil record
    assert_equal last_position+1, record.position
  end

  def test_search
    name = "petillant"
    get :index, :search => name
    assert_template 'list'
  end

  def test_show_action_should_not_be_recognized
    assert_raise(ActionController::UnknownAction) do
      get :show, :id => carbonation(:petillant).id
    end
  end

  def test_edit
    get :edit, :id => carbonation(:petillant).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = carbonation(:petillant)
    assert_no_difference 'Carbonation.count' do
      post :update, :id => record.id,
                    :record => { :description => "#{record.description} (modified)" }
    end
    assert_redirected_to admin_carbonation_index_path
  end

  def test_destroy
    record = carbonation(:petillant)
    assert_difference('Carbonation.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to admin_carbonation_index_path
  end

end
