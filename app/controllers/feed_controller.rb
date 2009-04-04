# -*- coding: utf-8 -*-

class FeedController < ApplicationController

  layout nil

  session :off

  before_filter :cache_as_xml

  caches_action :news

  def news
    @channel_name = competition_name
    @channel_description = "#{@channel_name} News"
    @news_items = NewsItem.find(:all, :order => 'coalesce(updated_at, created_at) desc', :limit => 5)
    headers["Content-Type"] = "application/rss+xml"
    respond_to do |format|
      format.xml
    end
  end

  private

    # Adapted from http://pocsw.com/2007/5/21/serving-action-cache-with-the-proper-content-type-in-rails
    # Since we've overridden ActionCachePath#path to exclude the host name, we leave it out here.
    def cache_as_xml
      # Building the fragment name
      fragment_name = request.env["REQUEST_URI"]
      fragment_name = fragment_name.last == "/" ? fragment_name.chomp("/") : fragment_name

      # Reading the fragment cache
      fragment = read_fragment(fragment_name)

      unless fragment.nil?
        # Set the content-type header
        headers["Content-Type"] = "application/rss+xml"

        # Deliver the content
        render :text => fragment

        # Halt any further processing
        return false
      end
    end

end
