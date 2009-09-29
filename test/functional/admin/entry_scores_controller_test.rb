# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::EntryScoresControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page title
    assert_select 'html > head > title', "#{@competition_name} Scores by Award Category"
    assert_select 'div#content > h1', "#{@competition_name} Scores by Award Category"

    # Verify the page contents
    awards = Award.find_public_awards
    assert_select 'div#content > div#scores-view > ul' do
      assert_select 'li', :count => awards.length
      awards.each do |award|
        expected_count = award.styles.inject(0){|acc,style| acc + style.entries.checked_in.length}
        assert_select "li#award#{award.id}-item > div.entries-for-award > div.active-scaffold" do
          assert_select 'div.active-scaffold-header > h2', award.name
          if expected_count > 0
            assert_select 'div > table > tbody.records > tr.record', :count => expected_count
          else
            assert_select 'div > table > tbody.messages' do
              assert_select 'tr', :count => 1
              assert_select 'p.empty-message', { :count => 1,
                                                 :text => I18n.t('active_scaffold.no_entries') }
            end
          end
        end
      end
    end
  end

  def test_new
    assert_raise(ActionController::UnknownAction) do
      get :new
    end
  end

  def test_create
    assert_raise(ActionController::UnknownAction) do
      get :new
    end
  end

  def test_show
    get :show, :id => entries(:i1_1D).id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => entries(:i1_1D).id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    # TODO: Figure out what to modify
    #record = entries(:i1_1D)
    #post :update, :id => record.id,
    #              :record => { 'What goes here?' }
    #assert_redirected_to admin_entry_score_path
  end

  def test_destroy_action_should_not_be_recognized
    assert_raise(ActionController::UnknownAction) do
      delete :destroy, :id => entries(:i1_1D).id
    end
  end

end
