# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/box_check_controller'

# Re-raise errors caught by the controller.
class Admin::BoxCheckController; def rescue_action(e) raise e end; end

class Admin::BoxCheckControllerTest < Test::Unit::TestCase

  def setup
    @controller = Admin::BoxCheckController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)

    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page content
    assert_select 'html > head > title', "#{@competition_name} Box Check"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Box Check"
      assert_select 'table', :count => 1
    end
  end

  def test_print
    get :index, :format => 'pdf'
    assert_response :success
    assert_pdf_response
  end
end
