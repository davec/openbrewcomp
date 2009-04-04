# -*- coding: utf-8 -*-

class CompetitionDataSweeper < ActionController::Caching::Sweeper
  observe CompetitionData

  def after_save(record)
    expire_fragments
  end

  private

    def expire_fragments
      expire_fragment(:controller => '/main', :action => 'index', :section => 'compname')
      expire_fragment(:controller => '/register', :action => 'forms', :section => 'compname')
      expire_fragment(:controller => '/sponsors', :action => 'index', :section => 'compname')
    end

end
