# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::BoxCheckControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
  end

  def test_should_generate_pdf
    get :index
    assert_response :success
    assert_pdf_response
  end
end
