# -*- coding: utf-8 -*-

class StyleSweeper < ActionController::Caching::Sweeper
  observe Style

  def after_save(record)
    expire_fragments
  end

  def after_destroy(record)
    expire_fragments
  end

  private

    def expire_fragments
      expire_fragment(:controller => '/styles', :action => 'index')
      expire_fragment(:controller => '/navbar', :action => 'styles')
      expire_fragment(:controller => '/entries', :action => 'awards')
      expire_fragment(:controller => '/register', :action => 'forms', :section => 'reqinfo')
    end

end
