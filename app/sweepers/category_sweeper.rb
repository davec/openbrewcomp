# -*- coding: utf-8 -*-

class CategorySweeper < ActionController::Caching::Sweeper
  observe Category

  def after_save(record)
    expire_fragments
  end

  def after_destroy(record)
    expire_fragments
  end

  private

    def expire_fragments
      expire_fragment(:controller => '/styles', :action => 'index')
    end

end
