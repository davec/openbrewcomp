# -*- coding: utf-8 -*-

class AwardSweeper < ActionController::Caching::Sweeper
  observe Award

  def after_save(record)
    expire_fragment(:styles_index)
  end

  alias after_destroy after_save

end
