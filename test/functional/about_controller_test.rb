# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class AboutControllerTest < ActionController::TestCase

  def setup
    @competition_name = CompetitionData.instance.name
  end

  def test_index
    get :index
    assert_response :success
  end

  def test_news
    get :news
    assert_response :success

    # Verify the page contents
    assert_select 'html > head > title', "#{@competition_name} News"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} News"
      assert_select 'div.news > dl' do
        assert_select 'dt', :count => NewsItem.count
        assert_select 'dd', :count => NewsItem.count do
          assert_select 'span.news-item-info', /Posted by/
        end
      end
    end
  end

  def test_missing_article
    get :article
    assert_response :success

    # Verify the page content
    assert_select 'html > head > title', "#{@competition_name} News"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} News"
      assert_select 'div.news' do
        assert_select 'dl', :count => 0
        assert_select 'p.flash-error', :count => 1
      end
    end
    assert_equal 'Missing article ID', flash[:error]
  end

  def test_unknown_article
    get :article, :id => 999
    assert_response :success

    # Verify the page content
    assert_select 'html > head > title', "#{@competition_name} News"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} News"
      assert_select 'div.news' do
        assert_select 'dl', :count => 0
        assert_select 'p.flash-error', :count => 1
      end
    end
    assert_match /article .* could not be found/, flash[:error]
  end

  def test_article
    get :article, :id => news_items(:post1).id
    assert_response :success

    # Verify the page content
    assert_select 'html > head > title', "#{@competition_name} News"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} News"
      assert_select 'div.news > dl' do
        assert_select 'dt', :count => 1
        assert_select 'dd', :count => 1 do
          assert_select 'span.news-item-info', /Posted by/
        end
      end
    end
    assert_nil flash[:error]
  end

  def test_contacts
    get :contacts
    assert_response :success

    # Verify the page content
    assert_select 'html > head > title', "#{@competition_name} Contacts"
    assert_select 'div#content' do
      assert_select 'h1', "#{@competition_name} Contacts"
      assert_select 'div.contacts' do
        assert_select 'dl' do
          assert_select 'dt', :count => Contact.count
        end
      end
    end

  end

  def test_faq
    get :faq
    assert_response :success
  end

end
