# -*- coding: utf-8 -*-

module ContactsHelper

  def coordinator_name
    @contacts['coordinator']['name']
  end
  def coordinator_email
    @contacts['coordinator']['email']
  end

  def webmaster_name
    @contacts['webmaster']['name']
  end
  def webmaster_email
    @contacts['webmaster']['email']
  end

  # Add additional contact_name/email methods as required

end
