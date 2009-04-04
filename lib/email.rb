# -*- coding: utf-8 -*-

module Email
  # Validate an email address
  def self.validate_address(addr)
    # FIXME: The following is incomplete
    /^[^@\s]+@([a-z0-9][-a-z0-9]*\.)+[a-z]{2,}$/i.match(addr)
  end
end
