# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class NewsItemTest < ActiveSupport::TestCase

  def test_should_create_new_news_item
    assert_difference 'NewsItem.count' do
      news_item = create_article
      assert !news_item.new_record?, "#{news_item.errors.full_messages.to_sentence}"
    end
  end

  def test_should_not_create_with_no_attributes
    assert_no_difference 'NewsItem.count' do
      news_item = create_article(:title => nil, :description_raw => nil)
      assert_equal I18n.t('activerecord.errors.messages.blank'), news_item.errors.on(:title)
      assert_equal I18n.t('activerecord.errors.messages.blank'), news_item.errors.on(:description_raw)
    end
  end

  def test_should_not_create_without_title
    assert_no_difference 'NewsItem.count' do
      news_item = create_article(:title => nil)
      assert_equal I18n.t('activerecord.errors.messages.blank'), news_item.errors.on(:title)
    end
  end

  def test_should_not_create_without_contents
    assert_no_difference 'NewsItem.count' do
      news_item = create_article(:description_raw => nil)
      assert_equal I18n.t('activerecord.errors.messages.blank'), news_item.errors.on(:description_raw)
    end
  end

  protected

    def create_article(options = {})
      record = NewsItem.new({ :description_raw => 'Some content for the story',
                              :title => 'A Title' }.merge(options))
      record.author = users(:admin)
      record.save
      record
    end

end
