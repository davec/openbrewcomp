# -*- coding: utf-8 -*-

class ContactSweeper < ActionController::Caching::Sweeper
  observe Contact

  def after_save(record)
    expire_fragment(:about_contacts)
  end

  alias after_destroy after_save

end
