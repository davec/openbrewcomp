# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ImportsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @competition_name = CompetitionData.instance.name

    # In non-admin mode, additional validity checks on the Judge model are
    # applied that are bypassed in admin mode.
    Controller.admin_view = true
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page title
    assert_select 'html > head > title', "#{@competition_name} Imports"
    assert_select 'div#content > h1', "#{@competition_name} Imports"
  end

  def test_db
    get :db
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', 'Competition Database Import'
    assert_select 'div#content' do
      assert_select 'h1', 'Competition Database Import'
      assert_select 'div#import-form' do
        assert_select 'form[enctype="multipart/form-data"][method=post]', :count => 1
      end
    end
  end

  def test_judges
    get :judges
    assert_response :success

    # Validate page contents
    assert_select 'html > head > title', 'BJCP Judge List Import'
    assert_select 'div#content' do
      assert_select 'h1', 'BJCP Judge List Import'
      assert_select 'div#import-form' do
        assert_select 'form[enctype="multipart/form-data"][method=post]', :count => 1
      end
    end
  end

  def test_judge_import
    import_file = 'test/mocks/judge_list_clean.tsv'
    import_count = File.new(import_file).read.split(/\r/).length

    assert_difference('Judge.count', import_count) do
      post :import_judges, { :file => { :file_data => uploadable_file(import_file) } }
    end
    assert_kind_of JudgeImport, assigns(:import)
    assert_not_nil assigns(:import)
    assert assigns(:import).valid?, 'Should be valid'
    assert_equal 0, assigns(:import).warnings.size, 'Should have no warnings'
    assert_equal 0, assigns(:import).errors.size, 'Should have no errors'
    assert_nil flash[:judge_import_warnings], 'Should have no warning messages'
    assert_nil flash[:judge_import_errors], 'Should have no error messages'
    assert_equal 'Judge list import was successful', flash[:notice]
    assert_redirected_to admin_path
  end

  def test_judge_import_with_warnings
    import_file = 'test/mocks/judge_list_with_warnings.tsv'
    import_count = File.new(import_file).read.split(/\r/).length
    # The test file has 2 records that should generate warnings:
    # 1. Invalid email address
    # 2. Unrecognized judge rank
    expected_warning_count = 2

    assert_difference('Judge.count', import_count) do
      post :import_judges, { :file => { :file_data => uploadable_file(import_file) } }
    end
    assert_kind_of JudgeImport, assigns(:import)
    assert_not_nil assigns(:import)
    assert assigns(:import).valid?, 'Should be valid'
    assert_equal expected_warning_count, assigns(:import).warnings.size, "Should have #{expected_warning_count} warnings"
    assert_equal 0, assigns(:import).errors.size, 'Should have no errors'
    assert_not_nil flash[:judge_import_warnings], 'Should have warning messages'
    assert_nil flash[:judge_import_errors], 'Should have no error messages'
    assert_redirected_to admin_import_judges_path
  end

  def test_judge_import_with_warnings_and_errors
    import_file = 'test/mocks/judge_list_with_warnings_and_errors.tsv'
    import_count = File.new(import_file).read.split(/\r/).length
    # The test file has 2 records that should generate warnings:
    # 1. Invalid email address
    # 2. Unrecognized judge rank
    expected_warning_count = 2
    # and one record that generates an error.
    expected_error_count = 1

    assert_difference('Judge.count', import_count - expected_error_count) do
      post :import_judges, { :file => { :file_data => uploadable_file(import_file) } }
    end
    assert_kind_of JudgeImport, assigns(:import)
    assert_not_nil assigns(:import)
    assert !assigns(:import).valid?, 'Should not be valid'
    assert_equal expected_warning_count, assigns(:import).warnings.size, "Should have #{expected_warning_count} warnings"
    assert_equal expected_error_count, assigns(:import).errors.size, "Should have #{expected_error_count} errors"
    assert_not_nil flash[:judge_import_warnings], 'Should have warning messages'
    assert_not_nil flash[:judge_import_errors], 'Should have no error messages'
    assert_redirected_to admin_import_judges_path
  end

  def test_judge_import_with_errors
    import_file = 'test/mocks/judge_list_with_errors.tsv'
    import_count = File.new(import_file).read.split(/\r/).length
    # The test file has 1 record that should generate an error
    expected_error_count = 1

    assert_difference('Judge.count', import_count - expected_error_count) do
      post :import_judges, { :file => { :file_data => uploadable_file(import_file) } }
    end
    assert_kind_of JudgeImport, assigns(:import)
    assert_not_nil assigns(:import)
    assert !assigns(:import).valid?, 'Should not be valid'
    assert_equal 0, assigns(:import).warnings.size, 'Should have no warnings'
    assert_equal expected_error_count, assigns(:import).errors.size, "Should have #{expected_error_count} errors"
    assert_nil flash[:judge_import_warnings], 'Should have no warning messages'
    assert_not_nil flash[:judge_import_errors], 'Should have error messages'
    assert_redirected_to admin_import_judges_path
  end

  # TODO: Figure out how to effectively test database imports

end
