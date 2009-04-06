# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'
require 'styles_controller'

# Re-raise errors caught by the controller.
class StylesController; def rescue_action(e) raise e end; end

class StylesControllerTest < Test::Unit::TestCase
  def setup
    @controller = StylesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Styles"
    assert_select 'div#content > h1', "#{@competition_name} Styles"
  end

  def test_all
    get :all
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', 'Complete List of Styles'
    assert_select 'div#content' do
      assert_select 'h1', 'Complete List of Styles'

      categories = Category.find(:all, :conditions => [ 'is_public = ?', true ])
      awards = Award.find_public_awards
      styles = Style.find(:all)

      assert_select 'h2', :count => categories.length
      #categories.each do |category|
      #  assert_select 'h2', category.name
      #end
      assert_select 'h3', :count => awards.length
      #awards.each do |award|
      #  assert_select 'h3', award.name
      #end
      assert_select 'dd', :count => styles.length
      #styles.each do |style|
      #  assert_select 'dd', "#{style.bjcp_category}#{style.bjcp_subcategory} #{style.name}"
      #end
    end
  end

end
