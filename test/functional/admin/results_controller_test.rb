# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ResultsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Results"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Results"

      # The rest of the page depends on the current state of judging

      ## Before judging is complete ...
      #assert_select 'p', :count => 1, :text => /Results cannot be generated/

      ## After second round judging is complete, but before BOS is complete
      #assert_select 'p', :count => 2
      #assert_select 'p:first-child', :text => /Results cannot be generated/
      #assert_select 'p:last-child', :text => /ineligible to judge/
      #assert_select 'div#ineligible-bos-judges > dl' do
      #  assert_select 'dt', :count => 2
      #  assert_select 'dd', :count => 2 do
      #    assert_select 'ul', :count => 1 do
      #      assert_select 'li', :minimum => 1  # TODO: Get actual count
      #    end
      #  end
      #end

      # After all judging is complete
      assert_select 'ul > li', :minimum => 1  # TODO: Get actual count
    end
  end

  def test_results_for_award_ceremony
    get :live
    assert_response :success

    # Validate the page contents
    assert_select 'html > head > title', "#{@competition_name} Awards"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Awards"
      assert_select 'table', :count => 4
    end
  end

  def test_results_for_web_page
    get :web
    assert_response :success

    # Validate the page contents
    assert_select 'html > head > title', "#{@competition_name} Awards"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Awards"
      assert_select 'table', :count => 4
    end
  end

  def test_results_for_web_page_download
    get :web, { :mode => 'download' }
    assert_response :success

    # Verify the downloaded file
    assert @response.headers['Content-Length'] > 0
    assert_equal 'text/plain', @response.headers['type']
    assert_match /<table class="resultstable"[^>]*>/, @response.body
  end

  def test_results_for_bjcp
    get :bjcp
    assert_response :success

    # Verify page contents
    assert_select 'html > head > title', "#{@competition_name} BJCP Competition Report"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} BJCP Competition Report"
      assert_select 'div#bjcp-report > div#competition-data > form[method=post]' do
        assert_select 'p:first-child > span.value', @competition_name
        assert_select 'p:nth-last-child(2) > textarea'
      end
    end
  end

  def test_results_for_bjcp_download
    comments_text = 'Competition comments'
    post :bjcp, :format => 'xml',
                :report => { :comments => comments_text }
    assert_response :success

    # Verify the downloaded file
    assert @response.headers['Content-Length'] > 0
    #assert_equal 'application/xml', @response.headers['type']
    assert_equal 'application/octet-stream', @response.headers['type']

    assert_select 'OrgReport' do
      assert_select 'CompData'
      assert_select 'BJCPpoints' do
        assert_select 'JudgeData', :count => 6
      end
      assert_select 'NonBJCP' do
        assert_select 'JudgeData', :count => 3
      end
      assert_select 'Comments', comments_text
      assert_select 'IPAddress'
      assert_select 'SubmissionDate', Time.now.strftime("%a, %d %B %Y %I:%M %P")
    end
  end

  def test_results_for_mcab
    get :mcab
    assert_response :success

    # Verify page contents
    assert_select 'html > head > title', "#{@competition_name} MCAB Report"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} MCAB Report"
      assert_select 'div#mcab-report > div#mcab-data' do
        assert_select 'div#qualifiers > ol > p', :count => 6
        assert_select 'form[method=post]'
      end
    end
  end

  def test_results_for_mcab_download
    post :mcab, :format => 'csv'
    assert_response :success

    # Verify the downloaded file
    assert @response.headers['Content-Length'] > 0
    #assert_equal 'text/csv', @response.headers['type']
    assert_equal 'application/octet-stream', @response.headers['type']
  end

  def test_results_generate_entrant_covers
    get :entrant_covers
    assert_response :success
    assert_pdf_response
  end

  def test_results_generate_entry_covers
    get :entry_covers
    assert_response :success
    assert_pdf_response
  end

  def test_results_scores
    get :scores
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} Entry Scores by Award Category"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Entry Scores by Award Category"
      assert_select 'table.reporttable > tbody' do
        awards = Award.find_public_awards.select{|award| award.styles.inject(0){|acc,style| acc + style.entries.checked_in.length} > 0}
        assert_select 'tr', :count => Entry.checked_in.length + awards.length
        assert_select 'tr.category-header', :count => awards.length
      end
    end

  end

end
