# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::MainControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Administration"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Administration"
      assert_select 'div#admin-menu > ul > li', :count => 6
    end
  end

end
