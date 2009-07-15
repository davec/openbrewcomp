# -*- coding: utf-8 -*-

class FeedController < ApplicationController
  layout nil

  # To get the correct MIME type applied to the RSS feed, we need to set the
  # Content-Type header in an after filter. Unless the feed is cached, then
  # the Content-Type header needs to be set in a before filter instead.
  after_filter  :set_content_type
  before_filter :set_content_type

  caches_action :news

  def news
    @channel_name = competition_name
    @channel_description = "#{@channel_name} News"
    @news_items = NewsItem.recent(5)

    respond_to do |format|
      format.xml
    end
  end

  private

    def set_content_type
      headers['Content-Type'] = 'application/rss+xml'
    end

end
