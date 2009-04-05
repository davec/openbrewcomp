# -*- coding: utf-8 -*-

class CategorySweeper < ActionController::Caching::Sweeper
  observe Category

  def after_save(record)
    expire_fragment(:styles_index)
  end

  alias after_destroy after_save

end
