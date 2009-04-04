# -*- coding: utf-8 -*-

class AboutController < ApplicationController

  helper :results
  helper :contacts

  def contacts
    unless read_fragment({})
      @contacts = Contact.to_hash
    end
  end

  def faq
    unless read_fragment({})
      contacts
    end
  end

  def news
    unless read_fragment({})
      @news_items = NewsItem.find(:all, :order => 'coalesce(updated_at, created_at) desc')
    end
  end

  def article
    # We can't cache individual articles
    unless params[:id].nil?
      begin
        @news_item = NewsItem.find(params[:id])
      rescue
        flash[:error] = 'The news article you requested could not be found.'
      end
    else
      flash[:error] = 'Missing article ID'
    end
  end

end
