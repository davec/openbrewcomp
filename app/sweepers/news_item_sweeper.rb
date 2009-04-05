# -*- coding: utf-8 -*-

class NewsItemSweeper < ActionController::Caching::Sweeper
  observe NewsItem

  def after_save(record)
    expire_fragment(:about_news)
    expire_action(:controller => '/feed', :action => 'news')
  end

  alias after_destroy after_save

end
