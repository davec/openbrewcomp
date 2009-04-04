# -*- coding: utf-8 -*-

class NewsItemSweeper < ActionController::Caching::Sweeper
  observe NewsItem

  def after_save(record)
    expire_fragments
  end

  def after_destroy(record)
    expire_fragments
  end

  private

    def expire_fragments
      expire_fragment(:controller => '/about', :action => 'news')

      expire_action(:controller => '/feed', :action => 'news')
    end

end
