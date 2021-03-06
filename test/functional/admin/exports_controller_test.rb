# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ExportsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page title
    assert_select 'html > head > title', "#{@competition_name} Exports"
    assert_select 'div#content > h1', "#{@competition_name} Exports"

    # Validate page contents
    assert_select 'div#content > ul' do
      assert_select 'li', :minimum => 1
    end
  end

  def test_csv
    get :index, :format => 'csv'
    assert_response :success
    assert_zip_response
  end

  def test_yaml
    get :index, :format => 'yaml'
    assert_response :success
    assert_zip_response
  end

end
