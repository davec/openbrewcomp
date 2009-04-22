# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class EntriesControllerTest < ActionController::TestCase

  def setup
    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page title
    assert_select 'html > head > title', "#{@competition_name} Rules"
    assert_select 'div#content > h1', "#{@competition_name} Rules"
  end

end
