# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::EntriesControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @good_entry = entries(:t1_1A)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_select 'div#content' do
      assert_select_active_scaffold_index_table [ Entry.count, 100 ].min
    end
  end

  def test_new
    # Cannot create a new entry from the entries scaffold; instead, it must be
    # created from an entries scaffold nested within the and entrants scaffold.
    assert_raise(ActionController::MethodNotAllowed) do
      get :new
    end
  end

  def test_create
    # Cannot create a new entry from the entries scaffold; instead, it must be
    # created from an entries scaffold nested within the and entrants scaffold.
    assert_raise(ActionController::MethodNotAllowed) do
      post :create, :record => { :style_id => styles(:style_1A).id }
    end
  end

  def test_search
    get :update_table, :search => Date.today.year
    assert_response :success
    assert_template '_list'
  end

  def test_show
    get :show, :id => @good_entry.id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => @good_entry.id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = @good_entry
    assert_no_difference 'Entry.count' do
      post :update, :id => record.id,
                    :record => { :name => 'New Name' }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_destroy
    record = @good_entry
    assert_difference('Entry.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_print
    get :print, :id => @good_entry.id
    assert_response :success
    assert_template 'print'
  end

  def test_help
    get :help
    assert_response :success
    assert_template 'help'
  end

  def test_bottle_labels
    login_as(:j_random_user)  # Can't do this as admin
    # HACK: EntriesController is not accessible to non-admins except when
    # nested within EntrantsController, so we need to fake the nesting.
    get :bottle_labels, :parent_model => 'Entrants'
    assert_response :success
    assert_pdf_response
  end

end
