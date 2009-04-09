# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/carbonation_controller'

# Re-raise errors caught by the controller.
class Admin::CarbonationController; def rescue_action(e) raise e end; end

class Admin::CarbonationControllerTest < Test::Unit::TestCase

  def setup
    @controller = Admin::CarbonationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
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
    assert_redirected_to :action => 'index'

    # Verify that the record's position is at the end of the list
    record = Carbonation.find_by_description(description)
    assert_not_nil record
    assert_equal last_position+1, record.position
  end

  def test_search
    get :update_table, :search => 'petillant'
    assert_response :success
    assert_template '_list'
  end

  def test_show
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
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = carbonation(:petillant)
    assert_difference('Carbonation.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

end
