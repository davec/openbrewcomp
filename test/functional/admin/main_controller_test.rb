# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/main_controller'

# Re-raise errors caught by the controller.
class Admin::MainController; def rescue_action(e) raise e end; end

class Admin::MainControllerTest < Test::Unit::TestCase

  def setup
    @controller = Admin::MainController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
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
