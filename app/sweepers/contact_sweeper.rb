# -*- coding: utf-8 -*-

class ContactSweeper < ActionController::Caching::Sweeper
  observe Contact

  def after_save(record)
    expire_fragments
  end

  def after_destroy(record)
    expire_fragments
  end

  private

    def expire_fragments
      expire_fragment(:controller => '/about', :action => 'contacts')
      expire_fragment(:controller => '/about', :action => 'faq')
      expire_fragment(:controller => '/sponsors', :action => 'index', :section => 'contacts')
    end

end
