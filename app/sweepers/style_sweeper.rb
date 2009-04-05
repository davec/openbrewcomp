# -*- coding: utf-8 -*-

class StyleSweeper < ActionController::Caching::Sweeper
  observe Style

  def after_save(record)
    expire_fragment(:styles_index)
    expire_fragment(:register_forms_required_info)
    expire_fragment(:navigation_styles)
  end

  alias after_destroy after_save

end
