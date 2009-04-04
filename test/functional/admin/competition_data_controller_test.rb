# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/competition_data_controller'

# Re-raise errors caught by the controller.
class Admin::CompetitionDataController; def rescue_action(e) raise e end; end

class Admin::CompetitionDataControllerTest < Test::Unit::TestCase

  def setup
    @controller = Admin::CompetitionDataController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)

    # Since we're mucking around and changing the competition data in many of
    # the tests, it must be reloaded prior to each test.
    CompetitionData.reload!
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table 1
    end
  end

  def test_new
    # The new action is disabled
    assert_raise(ActionController::UnknownAction) do
      get :new
    end
  end

  def test_create
    assert_raise(ActionController::UnknownAction) do
      post :create, :record => { :name => 'zilch' }
    end
  end

  def test_show
    get :show, :id => CompetitionData.instance.id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => CompetitionData.instance.id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = CompetitionData.instance
    assert_no_difference 'CompetitionData.count' do
      post :update, :id => record.id,
                    :record => { :name => "#{record.name} (modified)" }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    # The destroy action is disabled
    assert_raise(ActionController::UnknownAction) do
      delete :destroy, :id => CompetitionData.instance.id
    end
  end

end
